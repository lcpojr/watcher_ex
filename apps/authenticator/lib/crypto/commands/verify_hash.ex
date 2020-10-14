defmodule Authenticator.Crypto.Commands.VerifyHash do
  @moduledoc """
  Verify if a given hash matches the given value.
  """

  @typedoc "All possible hash algorithms"
  @type algorithms :: :argon2 | :bcrypt | :pbkdf2

  @doc "Verifies if a credential matches the given secret"
  @spec execute(credential :: map(), value :: String.t()) :: boolean()
  def execute(%{password: %{password_hash: hash, algorithm: algorithm}}, password)
      when is_binary(password),
      do: execute(password, hash, String.to_atom(algorithm))

  @doc "Verifies if a hash matches the given credential using the passed algorithm"
  @spec execute(value :: String.t(), hash :: String.t(), algorithm :: algorithms()) :: boolean()
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
