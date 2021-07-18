defmodule Authorizer.Input do
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

      @doc "Validates the given parameters and cast into #{__MODULE__} struct"
      @spec cast_and_apply(params :: map()) :: {:ok, __MODULE__.t()} | {:error, Changeset.t()}
      def cast_and_apply(params) when is_map(params) do
        params
        |> __MODULE__.changeset()
        |> case do
          %{valid?: true} = changeset -> {:ok, Changeset.apply_changes(changeset)}
          %{valid?: false} = changeset -> {:error, changeset}
        end
      end

      @doc "Cast #{__MODULE__} to a list"
      @spec cast_to_list(input :: __MODULE__.t()) :: list()
      def cast_to_list(%{__struct__: __MODULE__} = input) do
        input
        |> cast_to_map()
        |> Map.to_list()
        |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      end

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
