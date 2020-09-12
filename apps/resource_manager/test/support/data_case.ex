defmodule ResourceManager.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ecto
      import Ecto.Query
      import Mox
      import ResourceManager.{DataCase, Factory}

      alias ResourceManager.Repo

      setup :verify_on_exit!
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
