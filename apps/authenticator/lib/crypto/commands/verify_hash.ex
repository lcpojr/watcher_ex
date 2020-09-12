defmodule Authenticator.Crypto.Commands.VerifyHash do
  @moduledoc """
  Verify if a given hash matches the passed value
  """

  @behaviour ResourceManager.Credentials.Ports.VerifyHash

  @impl true
  def execute(value, hash, :argon2)
      when is_binary(value) and is_binary(hash),
      do: Argon2.verify_pass(value, hash)

  def execute(value, hash, :bcrypt)
      when is_binary(value) and is_binary(hash),
      do: Bcrypt.verify_pass(value, hash)

  def execute(value, hash, :pbkdf2)
      when is_binary(value) and is_binary(hash),
      do: Pbkdf2.verify_pass(value, hash)
end
