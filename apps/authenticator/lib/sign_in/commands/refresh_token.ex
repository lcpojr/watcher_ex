defmodule Authenticator.SignIn.Commands.RefreshToken do
  @moduledoc """
  Re authenticates the user identity using the Refresh Token Flow.

  This flow is used in order to exchange a refresh token in a new access token
  when the access token has expired.

  This allows clients to continue to have a valid access token without further
  interaction with the user.
  """

  require Logger

  alias Authenticator.{Repo, Sessions}
  alias Authenticator.Sessions.Commands.GetSession
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Inputs.RefreshToken, as: Input
  alias Ecto.Multi

  @behaviour Authenticator.SignIn.Commands.Behaviour

  @doc """
  Sign in an user identity by RefreshToken flow.

  The application has to be active and using openid-connect protocol.
  If the session was invalidated the flow will fail.
  """
  @impl true
  def execute(%Input{refresh_token: token}) do
    with {:token, {:ok, claims}} <- {:token, RefreshToken.verify_and_validate(token)},
         {:session, {:ok, session}} <- {:session, GetSession.execute(%{jti: claims["ati"]})},
         {:valid?, true} <- {:valid?, session.status not in ["invalidated", "refreshed"]},
         {:app, {:ok, app}} <- {:app, ResourceManager.get_identity(%{client_id: claims["aud"]})},
         {:flow_enabled?, true} <- {:flow_enabled?, "refresh_token" in app.grant_flows},
         {:valid_protocol?, true} <- {:valid_protocol?, app.protocol == "openid-connect"},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:subject, {:ok, subject}} <- {:subject, get_subject(session)},
         {:sub_active?, true} <- {:sub_active?, subject.status == "active"},
         {:ok, access_token, claims} <- generate_access_token(session.claims),
         {:ok, refresh_token, _} <- generate_refresh_token(claims),
         {:ok, _session} <- generate_session(session, claims) do
      {:ok, parse_response(access_token, refresh_token, claims)}
    else
      {:token, {:error, reason}} ->
        Logger.info("Failed to validate refresh token", error: inspect(reason))
        {:error, :unauthenticated}

      {:session, {:error, :not_found}} ->
        Logger.info("Failed to get access token")
        {:error, :unauthenticated}

      {:valid?, false} ->
        Logger.info("Session was invalidated")
        {:error, :unauthenticated}

      {:app, {:error, :not_found}} ->
        Logger.info("Client application not found")
        {:error, :unauthenticated}

      {:flow_enabled?, false} ->
        Logger.info("Client application refresh_token flow not enabled")
        {:error, :unauthenticated}

      {:valid_protocol?, false} ->
        Logger.info("Client application protocol is not openid-connect")
        {:error, :unauthenticated}

      {:app_active?, false} ->
        Logger.info("Client application is not active")
        {:error, :unauthenticated}

      {:subject, {:error, :not_found}} ->
        Logger.info("Subject not found")
        {:error, :unauthenticated}

      {:sub_active?, false} ->
        Logger.info("Subject is not active")
        {:error, :unauthenticated}

      error ->
        Logger.error("Failed to run command becuase of unknow error", error: inspect(error))
        error
    end
  end

  def execute(%{"grant_type" => "refresh_token"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(%{grant_type: "refresh_token"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(_any), do: {:error, :invalid_params}

  defp get_subject(%{subject_id: subject_id, subject_type: "user"}),
    do: ResourceManager.get_identity(%{username: nil, id: subject_id})

  defp get_subject(%{subject_id: subject_id, subject_type: "application"}),
    do: ResourceManager.get_identity(%{client_id: nil, id: subject_id})

  defp generate_access_token(%{"aud" => aud, "azp" => azp, "sub" => sub, "scope" => scope}) do
    AccessToken.generate_and_sign(%{
      "aud" => aud,
      "azp" => azp,
      "sub" => sub,
      "typ" => "Bearer",
      "scope" => scope
    })
  end

  defp generate_refresh_token(%{"aud" => aud, "azp" => azp, "jti" => jti}) do
    RefreshToken.generate_and_sign(%{
      "aud" => aud,
      "azp" => azp,
      "ati" => jti,
      "typ" => "Bearer"
    })
  end

  defp generate_session(session, %{"jti" => jti, "exp" => exp} = claims) do
    Multi.new()
    |> Multi.run(:update, fn _repo, _changes ->
      Sessions.update(session, %{status: "refreshed"})
    end)
    |> Multi.run(:create, fn _repo, _changes ->
      Sessions.create(%{
        jti: jti,
        subject_id: session.subject_id,
        subject_type: session.subject_type,
        claims: claims,
        expires_at: Sessions.convert_expiration(exp),
        grant_flow: "refresh_token"
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create: %Session{} = session}} ->
        Logger.info("Succeeds in generating a session", id: session.id)
        {:ok, session}

      {:error, step, reason, _changes} ->
        Logger.error("Failed to generate a session in step #{inspect(step)}", reason: reason)
        {:error, reason}
    end
  end

  defp parse_response(access_token, refresh_token, %{"exp" => exp, "scope" => scope}) do
    %{
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: Sessions.convert_expiration(exp),
      scope: scope
    }
  end
end
