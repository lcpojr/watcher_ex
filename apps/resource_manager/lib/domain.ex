defmodule ResourceManager.Domain do
  @moduledoc """
  Implements helpfull functions to be used in resource domains.
  """

  defmacro __using__(opts) do
    quote do
      alias ResourceManager.Repo

      require Logger

      @schema unquote(opts[:schema_model])

      @typedoc "Possible response types"
      @type response :: {:ok, @schema.t()} | {:error, Ecto.Changeset.t()}

      @doc "Creates a new #{@schema} with the given params"
      @spec create(params :: map()) :: response()
      def create(params) when is_map(params) do
        params
        |> @schema.changeset()
        |> Repo.insert()
        |> case do
          {:ok, _model} = response ->
            Logger.debug("#{inspect(@schema)} created with success")
            response

          {:error, reason} = response ->
            Logger.debug("#{inspect(@schema)} creation failed because #{inspect(reason)}")
            response
        end
      end

      @doc "Updates a #{@schema} with the given params"
      @spec update(model :: @schema.t(), params :: map()) :: response()
      def update(%@schema{} = model, params) when is_map(params) do
        model
        |> @schema.changeset(params)
        |> Repo.update()
        |> case do
          {:ok, _model} = response ->
            Logger.debug("#{inspect(@schema)} updated with success")
            response

          {:error, reason} = response ->
            Logger.debug("#{inspect(@schema)} update failed because #{inspect(reason)}")
            response
        end
      end

      @doc "Deletes a #{@schema} from the database"
      @spec delete(model :: @schema.t()) :: {:ok, @schema.t()}
      def delete(%@schema{} = model) do
        model
        |> Repo.delete()
        |> case do
          {:ok, _model} = response ->
            Logger.debug("#{inspect(@schema)} deleted with success")
            response

          {:error, reason} = response ->
            Logger.debug("#{inspect(@schema)} delete failed because #{inspect(reason)}")
            response
        end
      end

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
