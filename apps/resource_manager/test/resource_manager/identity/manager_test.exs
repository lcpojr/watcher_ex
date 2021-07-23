defmodule ResourceManager.Identities.ManagerTest do
  @moduledoc false

  use ResourceManager.DataCase, async: true

  alias ResourceManager.Identities.Manager
  alias ResourceManager.Ports.AuthenticatorMock
  alias ResourceManager.Identities.Schemas.{ClientApplication, User}

  describe "#{Manager}.execute/0" do
    setup do
      {:ok, user: insert!(:user), app: insert!(:client_application)}
    end

    test "succeeds and temporary blocks users", %{user: %{id: id, username: username}} do
      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :user -> {:ok, [username]} end)
      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :application -> {:ok, []} end)

      assert {:ok, :managed} == Manager.execute()
      assert %{status: "temporary_blocked", blocked_until: %{}} = Repo.get(User, id)
    end

    test "succeeds and temporary blocks applications", %{app: %{id: id, client_id: client_id}} do
      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :user -> {:ok, []} end)

      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :application ->
        {:ok, [client_id]}
      end)

      assert {:ok, :managed} == Manager.execute()
      assert %{status: "temporary_blocked", blocked_until: %{}} = Repo.get(ClientApplication, id)
    end

    test "succeeds and unblock users" do
      user = insert!(:user, status: "temporary_blocked", blocked_until: blocked_until())

      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :user -> {:ok, []} end)
      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :application -> {:ok, []} end)

      assert {:ok, :managed} == Manager.execute()
      assert %{status: "active", blocked_until: nil} = Repo.get(User, user.id)
    end

    test "succeeds and unblock applications" do
      app =
        insert!(
          :client_application,
          status: "temporary_blocked",
          blocked_until: blocked_until()
        )

      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :user -> {:ok, []} end)

      expect(AuthenticatorMock, :get_temporarilly_blocked, fn :application ->
        {:ok, [app.client_id]}
      end)

      assert {:ok, :managed} == Manager.execute()
      assert %{status: "active", blocked_until: nil} = Repo.get(ClientApplication, app.id)
    end
  end

  defp blocked_until do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(60 * -1, :second)
    |> NaiveDateTime.truncate(:second)
  end
end
