defmodule ResourceManager.Credentials.PublicKeysTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.PublicKeys
  alias ResourceManager.Credentials.Schemas.PublicKey

  setup do
    client_application = insert!(:client_application)
    public_key = insert!(:public_key, client_application_id: client_application.id)

    {:ok, client_application: client_application, public_key: public_key}
  end

  describe "#{PublicKeys}.create/1" do
    test "succeed if params are valid" do
      client_application = insert!(:client_application)

      params = %{
        client_application_id: client_application.id,
        value: get_priv_public_key()
      }

      assert {:ok, %PublicKey{id: id} = public_key} = PublicKeys.create(params)
      assert public_key == Repo.get(PublicKey, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [value: {"can't be blank", _}]}} =
               PublicKeys.create(%{client_application_id: ctx.client_application.id})
    end
  end

  describe "#{PublicKeys}.update/2" do
    test "succeed if params are valid", ctx do
      value = get_priv_public_key()

      assert {:ok, %PublicKey{id: id, value: ^value} = public_key} =
               PublicKeys.update(ctx.public_key, %{value: value})

      assert public_key == Repo.get(PublicKey, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [value: {"is invalid", _}]}} =
               PublicKeys.update(ctx.public_key, %{value: 123})
    end

    test "raises if public_key does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        PublicKeys.update(%PublicKey{}, %{value: get_priv_public_key()})
      end
    end
  end

  describe "#{PublicKeys}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %PublicKey{} = PublicKeys.get_by(id: ctx.public_key.id)
    end

    test "returns nil if nothing was found" do
      assert nil == PublicKeys.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{PublicKeys}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%PublicKey{}] = PublicKeys.list(id: ctx.public_key.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == PublicKeys.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{PublicKeys}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %PublicKey{id: id}} = PublicKeys.delete(ctx.public_key)
      assert nil == Repo.get(PublicKey, id)
    end

    test "raises if public_key does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        PublicKeys.delete(%PublicKey{})
      end
    end
  end
end
