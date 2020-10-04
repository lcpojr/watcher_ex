defmodule RestAPI.Ports.ResourceManager do
  @moduledoc """
  Port to access Authenticator domain commands.
  """

  @typedoc "All possible create_identity responses"
  @type possible_create_identity_response ::
          {:ok, struct()} | {:error, Ecto.Changeset.t() | :invalid_params}

  @doc "Delegates to Authenticator.sign_in_resource_owner/1"
  @callback create_identity(input :: map()) :: possible_create_identity_response()

  @doc "Authenticates the subject using Resource Owner Flow"
  @spec create_identity(input :: map()) :: possible_create_identity_response()
  def create_identity(input), do: implementation().create_identity(input)

  defp implementation do
    :rest_api
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:domain)
  end
end
