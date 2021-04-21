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

  @doc """
  A helper that transform changeset errors to a map of messages.
      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
