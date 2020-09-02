defmodule ResourceManager.Application do
  @moduledoc false

  use Application

  alias ResourceManager.Repo

  @doc false
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: ResourceManager.Supervisor)
  end

  defp children do
    [Repo]
  end
end
