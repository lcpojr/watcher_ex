defmodule ResourceManager.Factory do
  @moduledoc false

  alias ResourceManager.Credentials.Schemas.{Password, PublicKey}
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}
  alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, Scope, UserScope}
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
      client_id: Ecto.UUID.generate(),
      name: "my-application-name#{System.unique_integer()}",
      description: "It's a test application",
      grant_flows: ["resource_owner"],
      secret: gen_hashed_password(Ecto.UUID.generate(), :bcrypt)
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
      name: "identity:user:create#{System.unique_integer()}",
      description: "Can create user identities"
    }
  end

  def build(:user_scope) do
    %UserScope{
      user: build(:user),
      scope: build(:scope)
    }
  end

  def build(:client_application_scope) do
    %ClientApplicationScope{
      client_application: build(:client_application),
      scope: build(:scope)
    }
  end

  @doc false
  def build(factory_name, attributes) when is_atom(factory_name) and is_list(attributes) do
    factory_name
    |> build()
    |> struct!(attributes)
  end

  @doc false
  def insert!(factory_name, attributes \\ []) when is_atom(factory_name) do
    factory_name
    |> build(attributes)
    |> Repo.insert!()
  end

  @doc false
  def insert_list!(factory_name, count \\ 10, attributes \\ []) when is_atom(factory_name),
    do: Enum.map(0..count, fn _ -> insert!(factory_name, attributes) end)

  @doc false
  def gen_hashed_password(password \\ @default_password, alg \\ :argon2)
  def gen_hashed_password(password, :argon2), do: Argon2.hash_pwd_salt(password)
  def gen_hashed_password(password, :bcrypt), do: Bcrypt.hash_pwd_salt(password)
  def gen_hashed_password(password, :pbkdf2), do: Pbkdf2.hash_pwd_salt(password)

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
