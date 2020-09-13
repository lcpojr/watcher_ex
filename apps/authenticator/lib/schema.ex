defmodule Authenticator.Schema do
  @moduledoc """
  Implements helpfull functions to be used in database queries
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto.{Changeset, Query}

      alias Ecto.Queryable
      alias Authenticator.Repo

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id

      @doc "Gets one `#{__MODULE__}` filtering by the given fields"
      @spec one(fields :: keyword() | map()) :: Queryable.t()
      def one(fields) when is_list(fields) or is_map(fields) do
        fields
        |> query()
        |> Repo.one()
      end

      @doc "Gets many `#{__MODULE__}` filtering by the given fields"
      @spec many(fields :: keyword() | map()) :: list(Queryable.t())
      def many(fields) when is_list(fields) or is_map(fields) do
        fields
        |> query()
        |> Repo.all()
      end

      @doc "Checks if an `#{__MODULE__}` exists with the given fields"
      @spec exists?(fields :: keyword() | map()) :: boolean()
      def exists?(fields) when is_list(fields) or is_map(fields) do
        fields
        |> query()
        |> Repo.exists?()
      end

      @doc "Generates a query in `#{__MODULE__}` filtered by the given fields"
      @spec query(fields :: keyword() | map()) :: Queryable.t()
      def query(fields) do
        Enum.reduce(fields, Queryable.to_query(__MODULE__), &update_query(&2, &1))
      end

      defp update_query(%{from: %{source: {_table, schema}}} = queryable, {key, value})
           when is_atom(key) and not is_nil(value) do
        if key in schema.__schema__(:fields) do
          where(queryable, [c], field(c, ^key) == ^value)
        else
          custom_query(queryable, {key, value})
        end
      end

      defp custom_query(queryable, _any), do: queryable

      defoverridable custom_query: 2
    end
  end
end
