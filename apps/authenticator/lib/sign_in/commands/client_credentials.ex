defmodule Authenticator.SignIn.Commands.ClientCredentials do
  @moduledoc """
  Authenticates the client application identity using the Client Credentials Flow.

  With the client credentials grant type, the client application provides their
  secret (or client assertion) directly and we use it to authenticate before generating
  the access token.

  When a public key is registered for the client application this flow will require that
  an assertion is passed instead of the raw secret to avoid sending it on requests.

  This flow is used in machine-to-machine authentication and when the application already
  has user's permission or it's not required to access an specific data.
  """

  require Logger

  alias Authenticator.Ports.ResourceManager, as: Port
  alias Authenticator.Sessions
  alias Authenticator.Sessions.Tokens.{AccessToken, ClientAssertion, RefreshToken}
  alias Authenticator.SignIn.Inputs.ClientCredentials, as: Input
  alias ResourceManager.Permissions.Scopes

  @behaviour Authenticator.SignIn.Commands.Behaviour

  @doc """
  Sign in an client application identity by Client Credentials flow.

  The application has to be active, using openid-connect protocol in order to use this flow.

  When the client application has a public_key saved on database we force the use of
  client_assertions on input to avoid passing it's secret open on requests.

  If we fail in some step before verifying user password we have to fake it's verification
  to avoid exposing identity existance and time attacks.
  """
  @impl true
  def execute(%Input{client_id: client_id, scope: scope} = input) do
    with {:app, {:ok, app}} <- {:app, Port.get_identity(%{client_id: client_id})},
         {:flow_enabled?, true} <- {:flow_enabled?, "client_credentials" in app.grant_flows},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:secret_matches?, true} <- {:secret_matches?, secret_matches?(app, input)},
         {:valid_protocol?, true} <- {:valid_protocol?, app.protocol == "openid-connect"},
         {:ok, access_token, claims} <- generate_access_token(app, scope),
         {:ok, refresh_token, _} <- generate_refresh_token(app, claims),
         {:ok, _session} <- generate_session(claims) do
      {:ok, parse_response(access_token, refresh_token, claims)}
    else
      {:app, {:error, :not_found}} ->
        Logger.info("Client application #{client_id} not found")
        {:error, :unauthenticated}

      {:flow_enabled?, false} ->
        Logger.info("Client application #{client_id} client_credentials flow not enabled")
        {:error, :unauthenticated}

      {:app_active?, false} ->
        Logger.info("Client application #{client_id} is not active")
        {:error, :unauthenticated}

      {:secret_matches?, false} ->
        Logger.info("Client application #{client_id} credential didn't matches")
        {:error, :unauthenticated}

      {:confidential?, false} ->
        Logger.info("Client application #{client_id} is not confidential")
        {:error, :unauthenticated}

      {:valid_protocol?, false} ->
        Logger.info("Client application #{client_id} protocol is not openid-connect")
        {:error, :unauthenticated}

      error ->
        Logger.error("Failed to run command becuase of unknow error", error: inspect(error))
        error
    end
  end

  def execute(%{"grant_type" => "client_credentials"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(%{grant_type: "client_credentials"} = params) do
    params
    |> Input.cast_and_apply()
    |> case do
      {:ok, %Input{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(_any), do: {:error, :invalid_params}

  defp secret_matches?(%{client_id: id, public_key: public_key}, %{client_assertion: assertion})
       when is_binary(assertion) do
    signer = get_signer(public_key)

    assertion
    |> ClientAssertion.verify_and_validate(signer, %{client_id: id})
    |> case do
      {:ok, _claims} -> true
      {:error, _reason} -> false
    end
  end

  defp secret_matches?(%{public_key: nil, secret: app_secret}, %{client_secret: input_secret})
       when is_binary(app_secret) and is_binary(input_secret),
       do: app_secret == input_secret

  defp secret_matches?(_application, _input), do: false

  defp get_signer(%{value: pem, type: "rsa", format: "pem"}),
    do: Joken.Signer.create("RS256", %{"pem" => pem})

  defp build_scope(application, scopes) do
    app_scopes = Enum.map(application.scopes, & &1.name)

    scopes
    |> Scopes.convert_to_list()
    |> Enum.filter(&(&1 in app_scopes))
    |> Scopes.convert_to_string()
    |> case do
      "" -> nil
      scope -> scope
    end
  end

  defp generate_access_token(application, scope) do
    AccessToken.generate_and_sign(%{
      "aud" => application.client_id,
      "azp" => application.name,
      "sub" => application.id,
      "typ" => "Bearer",
      "identity" => "application",
      "scope" => build_scope(application, scope)
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
      subject_type: "application",
      claims: claims,
      expires_at: Sessions.convert_expiration(exp),
      grant_flow: "client_credentials"
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
