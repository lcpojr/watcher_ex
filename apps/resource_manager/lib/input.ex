defmodule ResourceManager.Input do
  @moduledoc """
  Implements helpfull functions to be used in inputs
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset

      alias Ecto.Changeset

      @primary_key false
      @foreign_key_type false

      @doc "Cast #{__MODULE__} to an atom map"
      @spec cast_to_map(input :: __MODULE__.t()) :: map()
      def cast_to_map(%{__struct__: __MODULE__} = input) do
        input
        |> Map.from_struct()
        |> Map.new(&do_cast_to_map/1)
      end

      defp do_cast_to_map(%Date{} = value), do: value
      defp do_cast_to_map(%DateTime{} = value), do: value
      defp do_cast_to_map(%NaiveDateTime{} = value), do: value
      defp do_cast_to_map(%Time{} = value), do: value
      defp do_cast_to_map([_ | _] = list), do: Enum.map(list, &do_cast_to_map/1)

      defp do_cast_to_map(%_struct{} = struct) do
        struct
        |> Map.from_struct()
        |> Map.new(&do_cast_to_map/1)
      end

      defp do_cast_to_map(value), do: value
    end
  end
end
