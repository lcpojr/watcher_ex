defmodule Authenticator.Factory do
  @moduledoc false

  alias Authenticator.Repo
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}

  @doc false
  def build(:session) do
    %Session{
      jti: Ecto.UUID.generate(),
      subject_id: Ecto.UUID.generate(),
      subject_type: "user",
      claims: %{},
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
    |> Path.join("/keys/authenticator.pub")
    |> File.read!()
  end

  @doc false
  def get_priv_private_key do
    :authenticator
    |> :code.priv_dir()
    |> Path.join("/keys/authenticator.pem")
    |> File.read!()
  end
end
