defmodule ResourceManager.Identity.ClientApplicationsTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.Ports.GenerateHashMock
  alias ResourceManager.Identity.ClientApplications
  alias ResourceManager.Identity.Schemas.ClientApplication

  setup do
    {:ok, client_application: insert!(:client_application)}
  end

  describe "#{ClientApplications}.create/1" do
    test "succeed if params are valid" do
      params = %{name: "my-test-application"}

      expect(GenerateHashMock, :execute, fn secret, :bcrypt ->
        assert is_binary(secret)
        gen_hashed_password(Ecto.UUID.generate())
      end)

      assert {:ok, %ClientApplication{id: id} = client_application} =
               ClientApplications.create(params)

      assert client_application == Repo.get(ClientApplication, id)
    end

    test "fails if params are invalid" do
      assert {:error, %{errors: [name: {"can't be blank", _}]}} = ClientApplications.create(%{})
    end
  end

  describe "#{ClientApplications}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %ClientApplication{name: "my-application-name", id: id} = app} =
               ClientApplications.update(ctx.client_application, %{
                 name: "my-application-name"
               })

      assert app == Repo.get(ClientApplication, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [name: {"is invalid", _}]}} =
               ClientApplications.update(ctx.client_application, %{name: 123})
    end

    test "raises if client_application does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        ClientApplications.update(%ClientApplication{}, %{name: "my-application-name"})
      end
    end
  end

  describe "#{ClientApplications}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %ClientApplication{} = ClientApplications.get_by(id: ctx.client_application.id)
    end

    test "returns nil if nothing was found" do
      assert nil == ClientApplications.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{ClientApplications}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%ClientApplication{}] = ClientApplications.list(id: ctx.client_application.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == ClientApplications.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{ClientApplications}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %ClientApplication{id: id}} = ClientApplications.delete(ctx.client_application)

      assert nil == Repo.get(ClientApplication, id)
    end

    test "raises if client_application does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        ClientApplications.delete(%ClientApplication{})
      end
    end
  end
end
