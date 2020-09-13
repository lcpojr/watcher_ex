defmodule Authenticator.Factory do
  @moduledoc false

  alias Authenticator.Repo
  alias Authenticator.Sessions.Schemas.AccessToken

  @doc false
  def build(:access_token) do
    %AccessToken{
      jti: Ecto.UUID.generate(),
      claims: %{},
      status: "active",
      grant_flow: "resource_owner",
      expires_at: default_expiration()
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
  def default_expiration do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(60 * 60 * 2, :second)
    |> NaiveDateTime.truncate(:second)
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
