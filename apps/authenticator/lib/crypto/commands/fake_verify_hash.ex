defmodule Authenticator.Crypto.Commands.FakeVerifyHash do
  @moduledoc """
  Simulates a hash verification using the given algorithm.
  """

  @behaviour ResourceManager.Credentials.Ports.FakeVerifyHash

  @impl true
  def execute(:argon2), do: Argon2.no_user_verify()
  def execute(:bcrypt), do: Bcrypt.no_user_verify()
  def execute(:pbkdf2), do: Pbkdf2.no_user_verify()
end
