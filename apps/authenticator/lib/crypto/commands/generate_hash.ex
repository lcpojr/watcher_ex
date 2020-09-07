defmodule Authenticator.Crypto.Commands.GenerateHash do
  @moduledoc """
  Generates a hash using the given parameters and algorithm.
  """

  @behaviour ResourceManager.Credentials.Ports.HashSecret

  @impl true
  def execute(v, :argon2) when is_map(v) or is_binary(v), do: Argon2.hash_pwd_salt(v)
  def execute(v, :bcrypt) when is_map(v) or is_binary(v), do: Bcrypt.hash_pwd_salt(v)
  def execute(v, :pbkdf2) when is_map(v) or is_binary(v), do: Pbkdf2.hash_pwd_salt(v)
end
