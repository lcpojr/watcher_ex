defmodule Authenticator.Sessions.Tokens.Hooks.ValidateEqualty do
  @moduledoc """
  Helper to validate if a given claims is are iguals.
  """

  use Joken.Hooks

  @impl true
  def after_validate([], _, _) do
    raise "Missing iqualty claims options"
  end

  def after_validate(claims_to_validate, _, _) when not is_list(claims_to_validate) do
    raise "Options must be a list of claim keys"
  end

  def after_validate(claims_to_validate, {:ok, claims} = result, input) do
    keys =
      claims_to_validate
      |> Enum.map(&convert_keys/1)
      |> MapSet.new()

    claims
    |> Enum.filter(fn {key, _value} -> key in keys end)
    |> Enum.uniq_by(fn {_key, value} -> value end)
    |> case do
      [] -> {:cont, result, input}
      claims -> {:halt, {:error, [message: "Invalid token", invalid_equalty: get_keys(claims)]}}
    end
  end

  def after_validate(_, result, input), do: {:cont, result, input}

  defp convert_keys(key) when is_binary(key), do: key
  defp convert_keys(key) when is_atom(key), do: Atom.to_string(key)

  defp get_keys(claims), do: Enum.map(claims, fn {key, _value} -> key end)
end
