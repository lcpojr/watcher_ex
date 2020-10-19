defmodule Authorizer.Policies.SubjectActiveTest do
  use Authorizer.DataCase, async: true

  alias Authorizer.Policies.SubjectActive
  alias Authorizer.Ports.ResourceManagerMock

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

  describe "#{SubjectActive}.validate/1" do
    test "succeed on validations if required params on conn", %{conn: conn} do
      assert {:ok, ^conn} = SubjectActive.validate(conn)
    end

    test "fails if conn do not have a session", %{conn: conn} do
      assert {:error, :unauthorized} == SubjectActive.validate(%{conn | private: %{session: nil}})
    end

    test "fails if conn session is invalid", %{conn: conn} do
      assert {:error, :unauthorized} == SubjectActive.validate(%{conn | private: %{session: %{}}})
    end
  end

  describe "#{SubjectActive}.execute/1" do
    test "succeeds if identity is active", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:ok, %{status: "active"}}
      end)

      assert {:ok, _shared_context} = SubjectActive.execute(conn)
    end

    test "fails if identity is not active", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:ok, %{status: "blocked"}}
      end)

      assert {:error, :unauthorized} == SubjectActive.execute(conn)
    end

    test "fails if identity was not found", %{conn: conn} do
      expect(ResourceManagerMock, :get_identity, fn %{id: user_id} ->
        assert conn.private.session.subject_id == user_id
        {:error, :not_found}
      end)

      assert {:error, :unauthorized} == SubjectActive.execute(conn)
    end
  end
end
