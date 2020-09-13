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
      grant_flow: "resource_owner"
    }
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
