defmodule Authenticator.Ports.ResourceManager do
  @moduledoc """
  Port to access ResourceManager domain commands.
  """

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, identity :: struct()} | {:error, :not_found | :invalid_params}

  @doc "Delegates to ResourceManager.get_identity/1"
  @callback get_identity(input :: map()) :: possible_responses()

  @doc "Gets the subject identity by its username or client_id"
  @spec get_identity(input :: map()) :: possible_responses()
  def get_identity(input), do: implementation().get_identity(input)

  @doc "Verifies if the given totp code matches the generated for the user"
  @spec valid_totp?(totp :: struct(), totp_code :: String.t()) :: boolean()
  def valid_totp?(totp, totp_code), do: implementation().valid_totp?(input)

  defp implementation do
    :authenticator
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:domain)
  end
end
