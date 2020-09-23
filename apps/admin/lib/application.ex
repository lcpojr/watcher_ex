defmodule Admin.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: Admin.Supervisor)
  end

  defp children do
    :admin
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:children)
  end

  def config_change(changed, _new, removed) do
    Admin.Endpoint.config_change(changed, removed)
    :ok
  end
end
