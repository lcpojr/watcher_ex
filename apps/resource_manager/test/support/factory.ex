defmodule ResourceManager.Factory do
  @moduledoc false

  alias ResourceManager.Credentials.Schemas.{Password, PublicKey}
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}
  alias ResourceManager.Permissions.Schemas.Scope
  alias ResourceManager.Repo

  @default_password "My-passw@rd123"

  @doc false
  def build(:user) do
    %User{
      username: "my-test-username#{System.unique_integer()}"
    }
  end

  def build(:client_application) do
    %ClientApplication{
      name: "My test application #{System.unique_integer()}",
      description: "It's a test application"
    }
  end

  def build(:password) do
    %Password{
      password_hash: gen_hashed_password()
    }
  end

  def build(:public_key) do
    %PublicKey{
      value: get_priv_public_key()
    }
  end

  def build(:scope) do
    %Scope{
      name: "identity:user:create",
      description: "Can create user identities"
    }
  end

  @doc false
  def build(factory_name, attributes) do
    factory_name
    |> build()
    |> struct!(attributes)
  end

  @doc false
  def insert!(factory_name, attributes \\ []) do
    factory_name
    |> build(attributes)
    |> Repo.insert!()
  end

  @doc false
  def gen_hashed_password(password \\ @default_password), do: Argon2.hash_pwd_salt(password)

  @doc false
  def get_priv_public_key do
    :resource_manager
    |> :code.priv_dir()
    |> Path.join("/keys/resource_manager_key.pub")
    |> File.read!()
  end

  @doc false
  def get_priv_private_key do
    :resource_manager
    |> :code.priv_dir()
    |> Path.join("/keys/resource_manager_key.pem")
    |> File.read!()
  end
end
