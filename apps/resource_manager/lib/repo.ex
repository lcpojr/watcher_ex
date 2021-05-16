defmodule ResourceManager.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :resource_manager, adapter: Ecto.Adapters.Postgres

  @doc "Encapsulates the given function into an transaction"
  @spec execute_transaction(fun :: function()) :: {:ok, any()} | {:error, any()}
  def execute_transaction(fun, opts \\ []) when is_function(fun) when is_list(opts) do
    transaction(fn ->
      case fun.() do
        :ok -> :ok
        {:ok, result} -> result
        {:error, reason} -> rollback(reason)
      end
    end)
  end
end
