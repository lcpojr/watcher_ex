defmodule Authenticator.Sessions.Tokens.Hooks.ValidateUUID do
  @moduledoc """
  Helper to validate if a given claim is a valid UUID.
  """

  use Joken.Hooks

  @impl true
  def after_validate([], _, _) do
    raise "Missing uuid claims options"
  end

  def after_validate(claims_to_validate, _, _) when not is_list(claims_to_validate) do
    raise "Options must be a list of claim keys"
  end

  def after_validate(claims_to_validate, {:ok, claims} = result, input) do
    keys =
      claims_to_validate
      |> Enum.map(&convert_keys/1)
      |> MapSet.new()

    # Trying to cast all uuid claims
    claims
    |> Enum.reduce([], fn {key, value}, acc ->
      if key in keys and not valid_uuid?(value) do
        [key | acc]
      else
        acc
      end
    end)
    |> case do
      [] -> {:cont, result, input}
      keys -> {:halt, {:error, [message: "Invalid token", invalid_uuid: keys]}}
    end
  end

  def after_validate(_, result, input), do: {:cont, result, input}

  defp convert_keys(key) when is_binary(key), do: key
  defp convert_keys(key) when is_atom(key), do: Atom.to_string(key)

  defp valid_uuid?(value) when is_binary(value) do
    value
    |> Ecto.UUID.cast()
    |> case do
      {:ok, _uuid} -> true
      _error -> false
    end
  end

  defp valid_uuid?(_claim), do: false
end
