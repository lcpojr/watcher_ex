defmodule Authenticator.Crypto.Commands.GenerateHash do
  @moduledoc """
  Generates a hash using the given parameters and algorithm.
  """

  @behaviour ResourceManager.Credentials.Ports.GenerateHash

  @impl true
  def execute(value, :argon2) when is_binary(value), do: Argon2.hash_pwd_salt(value)
  def execute(value, :bcrypt) when is_binary(value), do: Bcrypt.hash_pwd_salt(value)
  def execute(value, :pbkdf2) when is_binary(value), do: Pbkdf2.hash_pwd_salt(value)
end
