defmodule Authorizer.Rules.Commands.AuthorizationCodeSignIn do
  @moduledoc """
  Rule for authorizing a subject sign in on authorization code flow.
  """

  alias Authenticator.Sessions.Tokens.AuthorizationCode
  alias Authorizer.Ports.ResourceManager, as: Port
  alias Authorizer.Rules.Commands.Inputs.AuthorizationCodeSignIn, as: Input
  alias ResourceManager.Identities.Commands.Inputs.GetUser
  alias ResourceManager.Permissions.Scopes

  require Logger

  @typedoc "Authorization code success map response"
  @type success_map :: %{
          authorization_code: String.t(),
          expires_in: pos_integer(),
          token_type: String.t()
        }

  @doc """
  Run the authorization flow in order to verify if the subject matches all requirements.

  In order to authorize we have to execute an verification if the subject matches the
  following requirements:
    - The user has to have authorized the client;
    - The client has to have authorization code flow enabled;
    - The client has to be active;
    - The redirect uri should match the configured for the client;
    - The user has to be active;
  """
  @spec execute(input :: Input.t(), user_id :: String.t()) ::
          {:ok, success_map()} | {:error, :unauthorized}
  def execute(%Input{client_id: client_id} = input, user_id) when is_binary(user_id) do
    with {:authorized?, true} <- {:authorized?, input.authorized},
         {:app, {:ok, app}} <- {:app, Port.get_identity(%{client_id: client_id})},
         {:flow_enabled?, true} <- {:flow_enabled?, "authorization_code" in app.grant_flows},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:same_redirect?, true} <- {:same_redirect?, app.redirect_uri == input.redirect_uri},
         {:user, {:ok, user}} <- {:user, Port.get_identity(%GetUser{id: user_id})},
         {:user_active?, true} <- {:user_active?, user.status == "active"} do
      user
      |> generate_authorization_code(app, input.scope)
      |> parse_response()
    else
      {:authorized?, false} ->
        Logger.info("Client not authorized by the user")
        {:error, :unauthorized}

      {:app, {:error, :not_found}} ->
        Logger.info("Client application #{client_id} not found")
        {:error, :unauthorized}

      {:flow_enabled?, false} ->
        Logger.info("Client application #{client_id} resource_owner flow not enabled")
        {:error, :unauthorized}

      {:app_active?, false} ->
        Logger.info("Client application #{client_id} is not active")
        {:error, :unauthorized}

      {:same_redirect?, false} ->
        Logger.info("Request redirect_uri is different from the configured for the client")
        {:error, :unauthorized}

      {:user, {:error, :not_found}} ->
        Logger.info("User #{user_id} not found")
        {:error, :unauthorized}

      {:user_active?, false} ->
        Logger.info("User #{user_id} is not active")
        {:error, :unauthorized}
    end
  end

  defp generate_authorization_code(user, application, scope) do
    AuthorizationCode.generate_and_sign(%{
      "aud" => application.client_id,
      "azp" => application.name,
      "sub" => user.id,
      "typ" => "Bearer",
      "identity" => "user",
      "redirect_uri" => application.redirect_uri,
      "scope" => build_scope(user, application, scope)
    })
  end

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

  defp parse_response({:ok, code, %{"ttl" => ttl, "typ" => typ}}) do
    payload = %{
      authorization_code: code,
      expires_in: ttl,
      token_type: typ
    }

    {:ok, payload}
  end

  defp parse_response({:error, _reason} = error), do: error
end
