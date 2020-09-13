defmodule ResourceManager.Permissions.Scopes do
  @moduledoc false

  use ResourceManager.Domain, schema_model: ResourceManager.Permissions.Schemas.Scope

  @doc "Converts an binary scope input into a list"
  @spec convert_to_list(scope :: String.t()) :: list(String.t())
  def convert_to_list(scope) when is_binary(scope), do: String.split(scope, " ", trim: true)

  @doc "Converts an list of scope into a string"
  @spec convert_to_string(scopes :: list(String.t())) :: String.t()
  def convert_to_string(scopes) when is_list(scopes) do
    scopes
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
  end
end
