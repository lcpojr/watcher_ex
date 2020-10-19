defmodule Authorizer.Factory do
  @moduledoc false

  @doc "Extract the azp from the givem token claims"
  @spec extract_azp(claims :: map()) :: String.t() | nil
  def extract_azp(%{"azp" => azp}) when is_binary(azp), do: azp
  def extract_azp(_any), do: nil

  @doc "Extract the given scopes on claims and converts into a list of string"
  @spec extract_scopes(claims :: map()) :: list(String.t())
  def extract_scopes(%{"scope" => scope}) when is_binary(scope) do
    scope
    |> String.split(" ", trim: true)
    |> Enum.map(& &1)
  end

  def extract_scopes(_any), do: []
end
