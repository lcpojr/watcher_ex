defmodule RestApi.Application do
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: RestApi.Supervisor)
  end

  defp children do
    :rest_api
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:children)
  end

  @doc false
  def config_change(changed, _new, removed) do
    RestApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
