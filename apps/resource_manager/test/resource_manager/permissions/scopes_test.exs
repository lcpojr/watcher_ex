defmodule ResourceManager.Permissions.ScopesTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Permissions.Schemas.Scope
  alias ResourceManager.Permissions.Scopes

  setup do
    {:ok, scope: insert!(:scope)}
  end

  describe "#{Scopes}.create/1" do
    test "succeed if params are valid" do
      params = %{name: "identity:user:delete", description: "Can delete users"}
      assert {:ok, %Scope{id: id} = scope} = Scopes.create(params)
      assert scope == Repo.get(Scope, id)
    end

    test "fails if params are invalid" do
      assert {:error, %{errors: [name: {"can't be blank", _}]}} = Scopes.create(%{})
    end
  end

  describe "#{Scopes}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %Scope{id: id, description: "Can create users, but not admin"} = scope} =
               Scopes.update(ctx.scope, %{description: "Can create users, but not admin"})

      assert scope == Repo.get(Scope, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [name: {"is invalid", _}]}} =
               Scopes.update(ctx.scope, %{name: 123})
    end

    test "raises if scope does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Scopes.update(%Scope{}, %{description: "My new description"})
      end
    end
  end

  describe "#{Scopes}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %Scope{} = Scopes.get_by(id: ctx.scope.id)
    end

    test "returns nil if nothing was found" do
      assert nil == Scopes.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{Scopes}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%Scope{}] = Scopes.list(id: ctx.scope.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == Scopes.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{Scopes}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %Scope{id: id}} = Scopes.delete(ctx.scope)
      assert nil == Repo.get(Scope, id)
    end

    test "raises if scope does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Scopes.delete(%Scope{})
      end
    end
  end

  describe "#{Scopes}.convert_to_list/1" do
    test "succeed and return a list of scopes" do
      assert ["admin:read", "admin:write"] == Scopes.convert_to_list("admin:read admin:write")
    end

    test "succeed even if empty" do
      assert [] == Scopes.convert_to_list("")
    end
  end

  describe "#{Scopes}.convert_to_string/1" do
    test "succeed and return a scope string" do
      assert "admin:read admin:write" == Scopes.convert_to_string(["admin:read", "admin:write"])
    end

    test "succeed even if empty" do
      assert "" == Scopes.convert_to_string([])
    end
  end
end
