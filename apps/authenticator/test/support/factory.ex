defmodule Authenticator.Factory do
  @moduledoc false

  alias Authenticator.Repo
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}

  @doc false
  def build(:session) do
    jti = Ecto.UUID.generate()

    %Session{
      jti: jti,
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
  def build_access_token(claims), do: AccessToken.generate_and_sign(claims)

  @doc false
  def build_refresh_token(claims), do: RefreshToken.generate_and_sign(claims)

  @doc false
  def default_expiration do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.add(60 * 60 * 24, :second)
  end

  @doc false
  def get_priv_public_key do
    :authenticator
    |> :code.priv_dir()
    |> Path.join("/keys/authenticator_key.pub")
    |> File.read!()
  end

  @doc false
  def get_priv_private_key do
    :authenticator
    |> :code.priv_dir()
    |> Path.join("/keys/authenticator_key.pem")
    |> File.read!()
  end
end
