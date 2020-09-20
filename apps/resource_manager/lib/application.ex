defmodule ResourceManager.Application do
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: ResourceManager.Supervisor)
  end

  defp children do
    :resource_manager
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:children)
  end
end
