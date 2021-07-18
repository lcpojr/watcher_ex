defmodule Authenticator.SignIn.Commands.AuthorizationCode do
  @moduledoc """
  Authenticates the user identity using the Authorization Code Flow.

  This flow is used in order to exchange an authorization code in an access token.

  This allows clients to redirect the user to server in order to authenticate without having
  to request users credentials on their side.
  """

  require Logger

  alias Authenticator.Ports.ResourceManager, as: Port
  alias Authenticator.Sessions

  alias Authenticator.Sessions.Tokens.{
    AccessToken,
    AuthorizationCode,
    ClientAssertion,
    RefreshToken
  }

  alias Authenticator.SignIn.Commands.Inputs.AuthorizationCode, as: Input
  alias ResourceManager.Identities.Commands.Inputs.GetUser, as: User

  @behaviour Authenticator.SignIn.Commands.Behaviour

  @doc """
  Sign in an user identity by Authorization Code flow.

  The application has to be active, using openid-connect in order to use this flow.

  When the client application has a public_key saved on database we force the use of
  client_assertions on input to avoid passing it's secret open on requests.
  """
  @impl true
  def execute(%Input{code: token, client_id: client_id, redirect_uri: redirect_uri} = input) do
    with {:app, {:ok, app}} <- {:app, Port.get_identity(%{client_id: client_id})},
         {:flow_enabled?, true} <- {:flow_enabled?, "authorization_code" in app.grant_flows},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:valid_protocol?, true} <- {:valid_protocol?, app.protocol == "openid-connect"},
         {:token, {:ok, claims}} <- {:token, AuthorizationCode.verify_and_validate(token)},
         {:same_client?, true} <- {:same_client?, client_id == claims["aud"]},
         {:same_redirect?, true} <- {:same_redirect?, claims["redirect_uri"] == redirect_uri},
         {:user, {:ok, user}, _} <- {:user, Port.get_identity(%User{id: claims["sub"]}), claims},
         {:user_active?, true, _} <- {:user_active?, user.status == "active", claims},
         {:public?, true, _} <- {:public?, public_app?(app), {user, app, input, claims}} do
      geretate_tokens_and_parse_response(user, app, claims)
    else
      {:app, {:error, :not_found}} ->
        Logger.info("Client application #{client_id} not found")
        {:error, :unauthenticated}

      {:flow_enabled?, false} ->
        Logger.info("Client application #{client_id} resource_owner flow not enabled")
        {:error, :unauthenticated}

      {:app_active?, false} ->
        Logger.info("Client application #{client_id} is not active")
        {:error, :unauthenticated}

      {:valid_protocol?, false} ->
        Logger.info("Client application #{client_id} protocol is not openid-connect")
        {:error, :unauthenticated}

      {:token, {:error, reason}} ->
        Logger.info("Failed to validate authorization code token", error: inspect(reason))
        {:error, :unauthenticated}

      {:same_client?, false} ->
        Logger.info("Request client_id is different from the authorized")
        {:error, :unauthenticated}

      {:same_redirect?, false} ->
        Logger.info("Request redirect_uri is different from the authorized")
        {:error, :unauthenticated}

      {:user, {:error, :not_found}, %{"sub" => user_id}} ->
        Logger.info("User #{user_id} not found")
        {:error, :unauthenticated}

      {:user_active?, false, %{"sub" => user_id}} ->
        Logger.info("User #{user_id} is not active")
        {:error, :unauthenticated}

      {:public?, false, {user, app, input, claims}} ->
        Logger.info("Running confidential authentication flow for client #{client_id}")
        run_confidential_authentication(user, app, input, claims)

      error ->
        Logger.error("Failed to run command becuase of unknow error", error: inspect(error))
        error
    end
  end

  def execute(%{"grant_type" => "authorization_code"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(%{grant_type: "authorization_code"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  defp public_app?(%{access_type: "public"}), do: true
  defp public_app?(%{access_type: _any}), do: false

  defp run_confidential_authentication(user, app, input, claims) do
    if secret_matches?(app, input) do
      geretate_tokens_and_parse_response(user, app, claims)
    else
      Logger.info("Client application #{app.client_id} credential didn't matches")
      {:error, :unauthenticated}
    end
  end

  defp geretate_tokens_and_parse_response(user, app, claims) do
    user
    |> generate_tokens(app, claims)
    |> parse_response()
  end

  defp generate_tokens(user, app, %{"scope" => scope}) do
    with {:ok, access_token, claims} <- generate_access_token(user, app, scope),
         {:ok, refresh_token, _} <- generate_refresh_token(app, claims),
         {:ok, _session} <- generate_session(claims) do
      {:ok, access_token, refresh_token, claims}
    end
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

  defp generate_access_token(user, application, scope) do
    AccessToken.generate_and_sign(%{
      "aud" => application.client_id,
      "azp" => application.name,
      "sub" => user.id,
      "typ" => "Bearer",
      "identity" => "user",
      "scope" => scope
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

  defp parse_response({:ok, access_token, refresh_token, %{"ttl" => ttl, "typ" => typ}}) do
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
