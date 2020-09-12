defmodule Authenticator.SignIn.ResourceOwner do
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

  alias Authenticator.Crypto.Commands.VerifyHash
  alias Authenticator.Sessions.AccessToken
  alias Authenticator.SignIn.Inputs.ResourceOwner

  @typedoc "All possible responses"
  @type possible_responses ::
          {:ok, access_token :: String.t()}
          | {:error, Ecto.Changeset.t() | :anauthenticated}

  @doc "Sign in an user identity by ResouceOnwer flow"
  @spec execute(input :: ResourceOwner.t() | map()) :: possible_responses()
  def execute(%ResourceOwner{username: username, client_id: client_id} = input) do
    with {:app, {:ok, app}} <- {:app, ResourceManager.get_identity(%{client_id: client_id})},
         {:flow_enabled?, true} <- {:flow_enabled?, "resource_owner" in app.grant_flows},
         {:app_active?, true} <- {:app_active?, app.status == "active"},
         {:secret_matches?, true} <- {:secret_matches?, app.secret == input.client_secret},
         {:confidential?, true} <- {:confidential?, app.access_type == "confidential"},
         {:valid_protocol?, true} <- {:valid_protocol?, app.protocol == "openid-connect"},
         {:user, {:ok, user}} <- {:user, ResourceManager.get_identity(%{username: username})},
         {:user_active?, true} <- {:user_active?, user.status == "active"},
         {:pass_matches?, true} <- {:pass_matches?, VerifyHash.execute(user, input.password)} do
      generate_access_token(user, app, build_scopes(user, app, input.scope))
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

      {:secret_matches?, false} ->
        Logger.info("Client application #{client_id} secret do not match any credential")
        {:error, :unauthenticated}

      {:confidential?, false} ->
        Logger.info("Client application #{client_id} is not confidential")
        {:error, :unauthenticated}

      {:valid_protocol?, false} ->
        Logger.info("Client application #{client_id} protocol is not openid-connect")
        {:error, :unauthenticated}

      {:user, {:error, :not_found}} ->
        Logger.info("User #{username} not found")
        {:error, :unauthenticated}

      {:user_active?, false} ->
        Logger.info("User #{username} is not active")
        {:error, :unauthenticated}

      {:pass_matches?, false} ->
        Logger.info("User #{username} password do not match any credential")
        {:error, :unauthenticated}
    end
  end

  def execute(%{grant_type: "password"} = params) do
    params
    |> ResourceOwner.cast_and_apply()
    |> case do
      {:ok, %ResourceOwner{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(_any), do: {:error, :invalid_params}

  defp build_scopes(user, application, scopes) when is_binary(scopes) do
    user_scopes = Enum.map(user.scopes, & &1.name)
    app_scopes = Enum.map(application.scopes, & &1.name)

    scopes
    |> String.split(" ")
    |> Enum.filter(&(&1 in app_scopes))
    |> Enum.filter(&(&1 in user_scopes))
    |> Enum.join(" ")
  end

  defp generate_access_token(user, application, scope) do
    %{
      "aud" => application.client_id,
      "sub" => user.id,
      "typ" => "Bearer",
      "scope" => scope
    }
    |> AccessToken.generate_and_sign()
    |> case do
      {:ok, access_token, _claims} -> {:ok, access_token}
      error -> error
    end
  end
end
