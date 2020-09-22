defmodule RestAPI.Ports.SignIn do
  @moduledoc """
  Port to access Authenticator sign in command.
  """

  @typedoc "Token parameters to be sent on responses"
  @type token_params :: %{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_at: NaiveDateTime.t(),
          scope: String.t()
        }

  @typedoc "All possible responses"
  @type possible_responses ::
          {:ok, token_params()}
          | {:error, Ecto.Changeset.t() | :anauthenticated}

  @doc "Delegates to Authenticator.sign_in_resource_owner/1"
  @callback sign_in_resource_owner(input :: map()) :: possible_responses()

  @doc "Delegates to Authenticator.sign_in_refresh_token/1"
  @callback sign_in_refresh_token(input :: map()) :: possible_responses()

  @doc "Delegates to Authenticator.get_session/1"
  @callback get_session(input :: map()) :: possible_responses()

  @doc "Authenticates the subject using Resource Owner Flow"
  @spec sign_in_resource_owner(input :: map()) :: possible_responses()
  def sign_in_resource_owner(input), do: implementation().sign_in_resource_owner(input)

  @doc "Authenticates the subject using Refresh Token Flow"
  @spec sign_in_refresh_token(input :: map()) :: possible_responses()
  def sign_in_refresh_token(input), do: implementation().sign_in_refresh_token(input)

  @doc "Get's a session by the given input filters"
  @spec get_session(input :: map()) :: possible_responses()
  def get_session(input), do: implementation().get_session(input)

  defp implementation do
    :rest_api
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:domain)
  end
end
