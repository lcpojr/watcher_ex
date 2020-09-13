defmodule Authenticator.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ecto
      import Ecto.Query
      import Mox
      import Authenticator.{DataCase, Factory}

      alias Authenticator.Repo
      alias ResourceManager.Factory, as: RF

      setup :verify_on_exit!
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Authenticator.Repo)
    :ok = Sandbox.checkout(ResourceManager.Repo)

    unless tags[:async] do
      Sandbox.mode(Authenticator.Repo, {:shared, self()})
      Sandbox.mode(ResourceManager.Repo, {:shared, self()})
    end

    :ok
  end
end
