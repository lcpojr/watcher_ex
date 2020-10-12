defmodule Authenticator.Crypto.Commands.FakeVerifyHash do
  @moduledoc """
  Simulates a hash verification using the given algorithm.
  """

  @typedoc "All possible hash algorithms"
  @type algorithms :: :argon2 | :bcrypt | :pbkdf2

  @doc "Fake a hash verification using the given algorithm"
  @spec execute(algorithm :: algorithms()) :: false
  def execute(:argon2), do: Argon2.no_user_verify()
  def execute(:bcrypt), do: Bcrypt.no_user_verify()
  def execute(:pbkdf2), do: Pbkdf2.no_user_verify()
end
