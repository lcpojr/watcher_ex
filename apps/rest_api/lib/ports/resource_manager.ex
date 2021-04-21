defmodule RestAPI.Ports.ResourceManager do
  @moduledoc """
  Port to access Authenticator domain commands.
  """

  @typedoc "All possible create_identity responses"
  @type possible_response :: {:ok, struct()} | {:error, Ecto.Changeset.t()}

  @doc "Delegates to ResourceManager.create_user/1"
  @callback create_user(input :: map()) :: possible_response()

  @doc "Delegates to ResourceManager.create_client_application/1"
  @callback create_client_application(input :: map()) :: possible_response()

  @doc "Create a new user identity with it's credentials"
  @spec create_user(input :: map()) :: possible_response()
  def create_user(input), do: implementation().create_user(input)

  @doc "Create a new client application identity with it's credentials"
  @spec create_client_application(input :: map()) :: possible_response()
  def create_client_application(input), do: implementation().create_client_application(input)

  defp implementation do
    :rest_api
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:domain)
  end
end
