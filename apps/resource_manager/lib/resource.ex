defmodule ResourceManager.Resource do
  @moduledoc """
  Implements helpfull functions to be used in resource domains.
  """

  defmacro __using__(opts) do
    quote do
      alias ResourceManager.Repo

      @schema unquote(opts[:schema_model])

      @typedoc "Possible response types"
      @type response :: {:ok, @schema.t()} | {:error, Ecto.Changeset.t()}

      @doc "Creates a new #{@schema} with the given params"
      @spec create(params :: map()) :: response()
      def create(params) when is_map(params) do
        params
        |> @schema.changeset_create()
        |> Repo.insert()
      end

      @doc "Updates a #{@schema} with the given params"
      @spec update(model :: @schema.t(), params :: map()) :: response()
      def update(%@schema{} = model, params) when is_map(params) do
        model
        |> @schema.changeset_update(params)
        |> Repo.update()
      end

      @doc "Deletes a #{@schema} from the database"
      @spec delete(model :: @schema.t()) :: {:ok, @schema.t()}
      def delete(%@schema{} = model), do: Repo.delete(model)

      @doc "Checks if a #{@schema} exists with the given fields"
      @spec exists?(fields :: Keyword.t()) :: boolean()
      defdelegate exists?(fields), to: @schema

      @doc "Gets a #{@schema} with the given fields"
      @spec get_by(fields :: Keyword.t()) :: @schema.t() | nil
      defdelegate get_by(fields), to: @schema, as: :one

      @doc "Gets a list of #{@schema} with the given fields"
      @spec list(fields :: Keyword.t()) :: list(@schema.t())
      defdelegate list(fields), to: @schema, as: :many
    end
  end
end
