defmodule Authenticator.SignIn.Commands.ResourceOwner do
  @moduledoc """
  Authenticates the user identity using the Resource Owner Flow.

  With the resource owner password credentials grant type, the user provides their
  service credentials (username and password) directly and we uses it to authenticates
  then.

  The Client application should pass their secret in order to be authorized to exchange
  the credentials for an access_token.

  This grant type should only be enabled on the authorization server if other flows are not viable and
  should also only be used if the identity owner trusts in the application.
  """

  require Logger

  alias Authenticator.Crypto.Commands.{FakeVerifyHash, VerifyHash}
  alias Authenticator.Ports.ResourceManager, as: Port
  alias Authenticator.Sessions
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Inputs.ResourceOwner, as: Input
  alias ResourceManager.Permissions.Scopes

  @behaviour Authenticator.SignIn.Commands.Behaviour

  @doc """
  Sign in an user identity by ResouceOnwer flow.

  The application has to be active, using openid-connect protocol and with access_type
  confidential in order to use this flow.

  If we fail in some step before verifying user password we have to fake it's verification
  to avoid exposing identity existance and time attacks.
  """
  @impl true
  def execute(%Input{username: username, client_id: client_id, scope: scope} = input) do
    with {:app, {:ok, app}} <- {:app, Port.get_identity(%{client_id: client_id})},
         {:flow_enabled?, true} <- {:flow_enabled?, "resource_owner" in app.grant_flows},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:secret_matches?, true} <- {:secret_matches?, app.secret == input.client_secret},
         {:confidential?, true} <- {:confidential?, app.access_type == "confidential"},
         {:valid_protocol?, true} <- {:valid_protocol?, app.protocol == "openid-connect"},
         {:user, {:ok, user}} <- {:user, Port.get_identity(%{username: username})},
         {:user_active?, true} <- {:user_active?, user.status == "active"},
         {:pass_matches?, true} <- {:pass_matches?, VerifyHash.execute(user, input.password)},
         {:ok, access_token, claims} <- generate_access_token(user, app, scope),
         {:ok, refresh_token, _} <- generate_refresh_token(app, claims),
         {:ok, _session} <- generate_session(claims) do
      {:ok, parse_response(access_token, refresh_token, claims)}
    else
      {:app, {:error, :not_found}} ->
        Logger.info("Client application #{client_id} not found")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:flow_enabled?, false} ->
        Logger.info("Client application #{client_id} resource_owner flow not enabled")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:app_active?, false} ->
        Logger.info("Client application #{client_id} is not active")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:secret_matches?, false} ->
        Logger.info("Client application #{client_id} secret do not match any credential")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:confidential?, false} ->
        Logger.info("Client application #{client_id} is not confidential")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:valid_protocol?, false} ->
        Logger.info("Client application #{client_id} protocol is not openid-connect")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:user, {:error, :not_found}} ->
        Logger.info("User #{username} not found")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:user_active?, false} ->
        Logger.info("User #{username} is not active")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:pass_matches?, false} ->
        Logger.info("User #{username} password do not match any credential")
        {:error, :unauthenticated}

      error ->
        Logger.error("Failed to run command becuase of unknow error", error: inspect(error))
        error
    end
  end

  def execute(%{"grant_type" => "password"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(%{grant_type: "password"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(_any), do: {:error, :invalid_params}

  defp build_scope(user, application, scopes) do
    user_scopes = Enum.map(user.scopes, & &1.name)
    app_scopes = Enum.map(application.scopes, & &1.name)

    scopes
    |> Scopes.convert_to_list()
    |> Enum.filter(&(&1 in app_scopes))
    |> Enum.filter(&(&1 in user_scopes))
    |> Scopes.convert_to_string()
    |> case do
      "" -> nil
      scope -> scope
    end
  end

  defp generate_access_token(user, application, scope) do
    AccessToken.generate_and_sign(%{
      "aud" => application.client_id,
      "azp" => application.name,
      "sub" => user.id,
      "typ" => "Bearer",
      "identity" => "user",
      "scope" => build_scope(user, application, scope)
    })
  end

  defp generate_refresh_token(application, %{"aud" => aud, "azp" => azp, "jti" => jti}) do
    if "refresh_token" in application.grant_flows do
      RefreshToken.generate_and_sign(%{
        "aud" => aud,
        "azp" => azp,
        "ati" => jti,
        "typ" => "Bearer"
      })
    else
      Logger.info("Refresh token not enabled for application #{application.client_id}")
      {:ok, nil, nil}
    end
  end

  defp generate_session(%{"jti" => jti, "sub" => sub, "exp" => exp} = claims) do
    Sessions.create(%{
      jti: jti,
      subject_id: sub,
      subject_type: "user",
      claims: claims,
      expires_at: Sessions.convert_expiration(exp),
      grant_flow: "resource_owner"
    })
  end

  defp parse_response(access_token, refresh_token, %{"ttl" => ttl, "typ" => typ}) do
    %{
      access_token: access_token,
      refresh_token: refresh_token,
      expires_in: ttl,
      token_type: typ
    }
  end
end
