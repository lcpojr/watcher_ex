defmodule Authenticator.Sessions.SessionsTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.Sessions
  alias Authenticator.Sessions.Schemas.Session

  setup do
    {:ok, session: insert!(:session)}
  end

  describe "#{Sessions}.create/1" do
    test "succeed if params are valid" do
      params = %{
        jti: Ecto.UUID.generate(),
        type: "access_token",
        subject_id: Ecto.UUID.generate(),
        subject_type: "user",
        claims: %{},
        status: "active",
        grant_flow: "resource_owner",
        expires_at: default_expiration()
      }

      assert {:ok, %Session{id: id} = session} = Sessions.create(params)
      assert session == Repo.get(Session, id)
    end

    test "fails if params are invalid" do
      assert {:error, changeset} = Sessions.create(%{})

      assert %{
               type: ["can't be blank"],
               claims: ["can't be blank"],
               expires_at: ["can't be blank"],
               grant_flow: ["can't be blank"],
               jti: ["can't be blank"],
               subject_id: ["can't be blank"],
               subject_type: ["can't be blank"]
             } == errors_on(changeset)
    end
  end

  describe "#{Sessions}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %Session{id: id, status: "expired"} = session} =
               Sessions.update(ctx.session, %{status: "expired"})

      assert session == Repo.get(Session, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} = Sessions.update(ctx.session, %{status: 123})
      assert %{status: ["is invalid"]} == errors_on(changeset)
    end

    test "raises if session does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Sessions.update(%Session{}, %{status: "expired"})
      end
    end
  end

  describe "#{Sessions}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %Session{} = Sessions.get_by(id: ctx.session.id)
    end

    test "returns nil if nothing was found" do
      assert nil == Sessions.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{Sessions}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%Session{}] = Sessions.list(id: ctx.session.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == Sessions.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{Sessions}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %Session{id: id}} = Sessions.delete(ctx.session)
      assert nil == Repo.get(Session, id)
    end

    test "raises if session does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Sessions.delete(%Session{})
      end
    end
  end
end
