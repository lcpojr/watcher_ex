defmodule ResourceManager.Credentials.Passwords do
  @moduledoc """
  Passwords are a type of credential used by a subject in authentication requests.

  It's generally used by users in order to provide an minimum way to ensure
  that a it is who he claim to be when making requests.
  """

  use ResourceManager.Domain, schema_model: ResourceManager.Credentials.Schemas.Password

  alias ResourceManager.Credentials.Cache

  @doc "Checks if the given password is one of the most common passwords"
  @spec is_allowed?(password :: String.t()) :: boolean()
  def is_allowed?(password) when is_binary(password) do
    password
    |> Cache.get()
    |> case do
      nil -> false
      _any -> true
    end
  end
end
