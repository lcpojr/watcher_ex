defmodule Authenticator.Crypto.Commands.GenerateHash do
  @moduledoc """
  Generates a hash using the given parameters and algorithm (argon2, bcrypt or pbkdf2)

  # Argon2

  Argon2 is modern ASIC-resistant and GPU-resistant secure key derivation function.

  It accesses the memory array in a password dependent order, which reduces the possibility
  of time–memory trade-off (TMTO) attacks, but introduces possible side-channel attacks.

  In general it has better password cracking resistance than PBKDF2 and Bcrypt.

  # Bcrypt

  Bcrypt uses a salt to protect against rainbow table attacks and an adaptive function that
  can be configurated in order to increase the iteration count and it slower that makes it
  eiter resistant to brute-force attacks.

  # PBKDF2 (Password-Based Key Derivation Function 2)

  PBKF2 is a key derivation function (cryptographic hash function that derives one or more secret keys)
  with a sliding computational cost and generally used to reduce vulnerabilities to brute force attacks.
  """

  @behaviour ResourceManager.Credentials.Ports.GenerateHash

  @impl true
  def execute(value, :argon2) when is_binary(value), do: Argon2.hash_pwd_salt(value)
  def execute(value, :bcrypt) when is_binary(value), do: Bcrypt.hash_pwd_salt(value)
  def execute(value, :pbkdf2) when is_binary(value), do: Pbkdf2.hash_pwd_salt(value)
end
