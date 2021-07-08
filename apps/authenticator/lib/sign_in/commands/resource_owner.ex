defmodule Authenticator.SignIn.Commands.ResourceOwner do
  @moduledoc """
  Authenticates the user identity using the Resource Owner Flow.

  With the resource owner password credentials grant type, the user provides their
  username and password directly and we uses it to authenticates then.

  When dealing with public applications we cannot ensure that the secret is safe so
  we diden't request it unlike confidential applications where we can request a secret
  or an client_assertion.

  When a public key is registered for the client application this flow will require that
  an assertion is passed instead of the raw secret to avoid sending it on requests.

  This grant type should only be enabled on the authorization server if other flows are not viable and
  should also only be used if the identity owner trusts in the application.
  """

  require Logger

  alias Authenticator.Crypto.Commands.{FakeVerifyHash, VerifyHash}
  alias Authenticator.Ports.ResourceManager, as: Port
  alias Authenticator.{Repo, Sessions}
  alias Authenticator.Sessions.Tokens.{AccessToken, ClientAssertion, RefreshToken}
  alias Authenticator.SignIn.Commands.Inputs.ResourceOwner, as: Input
  alias Authenticator.SignIn.UserAttempts
  alias Ecto.Multi
  alias ResourceManager.Permissions.Scopes

  @behaviour Authenticator.SignIn.Commands.Behaviour

  @doc """
  Sign in an user identity by ResouceOnwer flow.

  The application has to be active, using openid-connect in order to use this flow.

  When the client application has a public_key saved on database we force the use of
  client_assertions on input to avoid passing it's secret open on requests.

  If we fail in some step before verifying user password we have to fake it's verification
  to avoid exposing identity existance and time attacks.
  """
  @impl true
  def execute(%Input{username: username, client_id: client_id} = input) do
    with {:app, {:ok, app}} <- {:app, Port.get_identity(%{client_id: client_id})},
         {:flow_enabled?, true} <- {:flow_enabled?, "resource_owner" in app.grant_flows},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:valid_protocol?, true} <- {:valid_protocol?, app.protocol == "openid-connect"},
         {:user, {:ok, user}} <- {:user, Port.get_identity(%{username: username})},
         {:user_active?, true} <- {:user_active?, user.status == "active"},
         {:public?, true, _identities} <- {:public?, app.access_type == "public", {user, app}} do
      Logger.info("Running public authentication flow for client #{client_id}")
      run_public_authentication(user, app, input)
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

      {:public?, false, {user, app}} ->
        Logger.info("Running confidential authentication flow for client #{client_id}")
        run_confidential_authentication(user, app, input)

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

  defp run_public_authentication(user, app, %{password: password, otp: otp} = input) do
    if VerifyHash.execute(user, password) and valid_totp?(user, otp) do
      geretate_tokens_and_parse_response(user, app, input)
    else
      Logger.info("User #{user.username} password do not match any credential")
      generate_attempt(input, false)
      {:error, :unauthenticated}
    end
  end

  defp valid_totp?(%{totp: nil}, nil), do: true
  defp valid_totp?(%{totp: nil}, code) when is_binary(code), do: false
  defp valid_totp?(%{totp: totp}, code) when is_binary(code), do: Port.valid_totp?(totp, code)

  defp run_confidential_authentication(user, app, input) do
    with {:secret_matches?, true} <- {:secret_matches?, secret_matches?(app, input)},
         {:pass_matches?, true} <- {:pass_matches?, VerifyHash.execute(user, input.password)} do
      geretate_tokens_and_parse_response(user, app, input)
    else
      {:secret_matches?, false} ->
        Logger.info("Client application #{app.client_id} credential didn't matches")
        FakeVerifyHash.execute(:argon2)
        {:error, :unauthenticated}

      {:pass_matches?, false} ->
        Logger.info("User #{user.username} password do not match any credential")
        generate_attempt(input, false)
        {:error, :unauthenticated}
    end
  end

  defp geretate_tokens_and_parse_response(user, app, input) do
    user
    |> generate_tokens(app, input)
    |> parse_response()
  end

  defp generate_tokens(user, app, input) do
    Repo.execute_transaction(fn ->
      with {:ok, access_token, access_claims} <- generate_access_token(user, app, input.scope),
           {:ok, refresh_token, refresh_claims} <- generate_refresh_token(app, access_claims),
           {:ok, _session} <- generate_session(input, access_claims, "access_token"),
           {:ok, _session} <- generate_session(input, refresh_claims, "refresh_token") do
        {:ok, {access_token, refresh_token, access_claims}}
      end
    end)
  end

  defp secret_matches?(%{client_id: id, public_key: public_key}, %{client_assertion: assertion})
       when is_binary(assertion) do
    signer = get_signer_context(public_key)

    assertion
    |> ClientAssertion.verify_and_validate(signer, %{client_id: id})
    |> case do
      {:ok, _claims} -> true
      {:error, _reason} -> false
    end
  end

  defp secret_matches?(%{public_key: nil, secret: secret}, %{client_secret: secret}), do: true
  defp secret_matches?(_application, _input), do: false

  defp get_signer_context(%{value: pem, type: "rsa", format: "pem"}),
    do: Joken.Signer.create("RS256", %{"pem" => pem})

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

  defp generate_refresh_token(application, %{
         "aud" => aud,
         "azp" => azp,
         "jti" => jti,
         "sub" => sub
       }) do
    if "refresh_token" in application.grant_flows do
      RefreshToken.generate_and_sign(%{
        "aud" => aud,
        "sub" => sub,
        "azp" => azp,
        "ati" => jti,
        "typ" => "Bearer"
      })
    else
      Logger.info("Refresh token not enabled for application #{application.client_id}")
      {:ok, nil, nil}
    end
  end

  defp generate_session(_input, nil, _type), do: {:ok, :ignored}

  defp generate_session(input, claims, "access_token" = type) do
    Multi.new()
    |> Multi.run(:save_attempt, fn _repo, _changes -> generate_attempt(input, true) end)
    |> Multi.run(:generate, fn _repo, _changes -> generate_session(claims, type) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{generate: session}} ->
        Logger.info("Succeeds in access token creating session", id: session.id)
        {:ok, session}

      {:error, step, reason, _changes} ->
        Logger.error("Failed to create access token session in step #{inspect(step)}",
          reason: reason
        )

        {:error, reason}
    end
  end

  defp generate_session(_input, claims, "refresh_token" = type) do
    case generate_session(claims, type) do
      {:ok, session} ->
        Logger.info("Succeeds in creating refresh token session", id: session.id)
        {:ok, session}

      {:error, reason} = error ->
        Logger.error("Failed to create refresh token session", reason: reason)
        error
    end
  end

  defp generate_attempt(%{username: username, ip_address: ip_address}, success?) do
    UserAttempts.create(%{
      username: username,
      was_successful: success?,
      ip_address: ip_address
    })
  end

  defp generate_session(%{"jti" => jti, "sub" => sub, "exp" => exp} = claims, type) do
    Sessions.create(%{
      jti: jti,
      type: type,
      subject_id: sub,
      subject_type: "user",
      claims: claims,
      expires_at: Sessions.convert_expiration(exp),
      grant_flow: "resource_owner"
    })
  end

  defp parse_response({:ok, {access_token, refresh_token, %{"ttl" => ttl, "typ" => typ}}}) do
    payload = %{
      access_token: access_token,
      refresh_token: refresh_token,
      expires_in: ttl,
      token_type: typ
    }

    {:ok, payload}
  end

  defp parse_response({:error, _reason} = error), do: error
end
