defmodule Authorizer.Rules.Commands.AdminAccessTest do
  @moduledoc false

  use Authorizer.DataCase, async: true

  alias Authorizer.Ports.ResourceManagerMock
  alias Authorizer.Rules.Commands.AdminAccess

  setup do
    conn = %Plug.Conn{
      private: %{
        session: %{
          id: Ecto.UUID.generate(),
          jti: Ecto.UUID.generate(),
          subject_id: Ecto.UUID.generate(),
          subject_type: "user",
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(), 10_000),
          scopes: ["admin:read", "admin.write"],
          azp: "Watcher Ex"
        }
      }
    }

    {:ok, conn: conn}
  end

  describe "#{AdminAccess}.execute/1" do
    test "succeeds if subject is active and is an admin", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:ok, %{status: "active", is_admin: true}}
      end)

      assert :ok == AdminAccess.execute(conn)
    end

    test "fails if identity is not an admin", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:ok, %{status: "active", is_admin: false}}
      end)

      assert {:error, :unauthorized} == AdminAccess.execute(conn)
    end

    test "fails if identity is not active", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:ok, %{status: "blocked", is_admin: true}}
      end)

      assert {:error, :unauthorized} == AdminAccess.execute(conn)
    end

    test "fails if identity was not found", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:error, :not_found}
      end)

      assert {:error, :unauthorized} == AdminAccess.execute(conn)
    end
  end
end
