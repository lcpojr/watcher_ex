defmodule Authenticator.Factory do
  @moduledoc false

  alias Authenticator.Repo
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, AuthorizationCode, RefreshToken}
  alias Authenticator.SignIn.Schemas.{ApplicationAttempt, UserAttempt}

  @doc "Builds a default struct from the requested model"
  @spec build(model :: atom()) :: struct()
  def build(:session) do
    jti = Ecto.UUID.generate()

    %Session{
      jti: jti,
      type: "access_token",
      subject_id: Ecto.UUID.generate(),
      subject_type: "user",
      claims: %{
        "aud" => "2e455bb1-0604-4812-9756-36f7ab23b8d9",
        "azp" => "admin",
        "exp" => :os.system_time(:millisecond),
        "iat" => 1_600_976_621,
        "iss" => "WatcherEx",
        "jti" => jti,
        "nbf" => :os.system_time(:millisecond),
        "scope" => "admin:read admin:write",
        "sub" => "7f5eb9dc-b550-4586-91dc-3c701eb3b9bc",
        "ttl" => 7200,
        "typ" => "Bearer"
      },
      status: "active",
      grant_flow: "resource_owner",
      expires_at: default_expiration(),
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end

  def build(:user_sign_in_attempt) do
    %UserAttempt{
      username: Ecto.UUID.generate(),
      was_successful: true,
      ip_address: "45.232.192.12"
    }
  end

  def build(:application_sign_in_attempt) do
    %ApplicationAttempt{
      client_id: Ecto.UUID.generate(),
      was_successful: true,
      ip_address: "45.232.192.12"
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

  @doc "Returns an mocked access token using the given claims"
  @spec build_access_token(claims :: map()) :: {:ok, token :: String.t(), claims :: map()}
  def build_access_token(claims) when is_map(claims), do: AccessToken.generate_and_sign(claims)

  @doc "Returns an mocked refresh token using the given claims"
  @spec build_refresh_token(claims :: map()) :: {:ok, token :: String.t(), claims :: map()}
  def build_refresh_token(claims) when is_map(claims), do: RefreshToken.generate_and_sign(claims)

  @doc "Returns an mocked authorization code token using the given claims"
  @spec build_authorization_code_token(claims :: map()) ::
          {:ok, token :: String.t(), claims :: map()}
  def build_authorization_code_token(claims) when is_map(claims),
    do: AuthorizationCode.generate_and_sign(claims)

  @doc "Returns an default token expiration"
  @spec default_expiration() :: NaiveDateTime.t()
  def default_expiration do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.add(60 * 60 * 24, :second)
  end

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
