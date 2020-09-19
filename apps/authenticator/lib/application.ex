defmodule Authenticator.Application do
  @moduledoc false

  use Application

  alias Authenticator.Repo

  @doc false
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: Authenticator.Supervisor)
  end

  defp children do
    [Repo]
  end
end
