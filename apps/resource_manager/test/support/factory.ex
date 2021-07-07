defmodule ResourceManager.Factory do
  @moduledoc false

  alias ResourceManager.Credentials.Schemas.{Password, PublicKey, TOTP}
  alias ResourceManager.Identities.Schemas.{ClientApplication, User}
  alias ResourceManager.Permissions.Schemas.{ClientApplicationScope, Scope, UserScope}
  alias ResourceManager.Repo

  @default_password "My-passw@rd123"

  @doc "Builds a default struct from the requested model"
  @spec build(model :: atom()) :: struct()
  def build(:user) do
    %User{
      username: "my-test-username#{System.unique_integer()}",
      status: "active",
      is_admin: false
    }
  end

  def build(:client_application) do
    %ClientApplication{
      client_id: Ecto.UUID.generate(),
      name: "my-application-name#{System.unique_integer()}",
      description: "It's a test application",
      grant_flows: ["resource_owner"],
      status: "active",
      protocol: "openid-connect",
      access_type: "public",
      is_admin: false,
      secret: gen_hashed_password(Ecto.UUID.generate(), :bcrypt)
    }
  end

  def build(:password) do
    %Password{
      password_hash: gen_hashed_password()
    }
  end

  def build(:totp) do
    %TOTP{
      secret: gen_totp_secret(),
      otp_uri: "otpauth://totp/:label?:query"
    }
  end

  def build(:public_key) do
    %PublicKey{
      value: get_public_key()
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

  @doc "Returns the a model struct with the given attributes"
  @spec build(factory_name :: atom(), attributes :: Keyword.t()) :: struct()
  def build(factory_name, attributes) when is_atom(factory_name) and is_list(attributes) do
    factory_name
    |> build()
    |> struct!(attributes)
  end

  @doc "Inserts a model with the given attributes on database"
  @spec insert!(factory_name :: atom(), attributes :: Keyword.t()) :: struct()
  def insert!(factory_name, attributes \\ []) when is_atom(factory_name) do
    factory_name
    |> build(attributes)
    |> Repo.insert!()
  end

  @doc "Inserts a list of the given model on database"
  @spec insert_list!(
          factory_name :: atom(),
          count :: integer(),
          attributes :: Keyword.t()
        ) :: list(struct())
  def insert_list!(factory_name, count \\ 10, attributes \\ []) when is_atom(factory_name),
    do: Enum.map(0..count, fn _ -> insert!(factory_name, attributes) end)

  @doc "Returns the given password hashed using the selected algorithm"
  @spec gen_hashed_password(
          password :: String.t(),
          algorithm :: :argon2 | :bcrypt | :pbkdf2
        ) :: String.t()
  def gen_hashed_password(password \\ @default_password, alg \\ :argon2)

  def gen_hashed_password(password, :argon2) when is_binary(password),
    do: Argon2.hash_pwd_salt(password)

  def gen_hashed_password(password, :bcrypt) when is_binary(password),
    do: Bcrypt.hash_pwd_salt(password)

  def gen_hashed_password(password, :pbkdf2) when is_binary(password),
    do: Pbkdf2.hash_pwd_salt(password)

  @doc "Generates an random totp secret"
  @spec gen_totp_secret() :: String.t()
  def gen_totp_secret, do: Base.encode32(:crypto.strong_rand_bytes(20), padding: false)

  @doc "Returns the mocked public key"
  @spec get_public_key() :: String.t()
  def get_public_key do
    File.cwd!()
    |> Path.join("/test/support/mocks/keys/public_key.pub")
    |> File.read!()
  end

  @doc "Returns the mocked private key"
  @spec get_private_key() :: String.t()
  def get_private_key do
    File.cwd!()
    |> Path.join("/test/support/mocks/keys/private_key.pem")
    |> File.read!()
  end
end
