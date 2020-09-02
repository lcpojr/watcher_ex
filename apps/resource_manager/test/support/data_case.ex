defmodule ResourceManager.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import ResourceManager.{DataCase, Factory}

      alias ResourceManager.Repo
    end
  end

  setup tags do
    :ok = Sandbox.checkout(ResourceManager.Repo)

    unless tags[:async] do
      Sandbox.mode(ResourceManager.Repo, {:shared, self()})
    end

    :ok
  end
end
