defmodule ResourceManager.Credentials.Ports.FakeVerifyHash do
  @moduledoc """
  Port to access Authenticator fake verify hash command.
  """

  @doc "Delegates to #{__MODULE__}.execute/1 command"
  @callback execute(algorithm :: :argon2 | :bcrypt | :pbkdf2) :: false

  @doc "Gets the hash and algorithm from the input and verifies if it matches the hash"
  @spec execute(algorithm :: :argon2 | :bcrypt | :pbkdf2) :: false
  def execute(algorithm), do: implementation().execute(algorithm)

  defp implementation do
    :resource_manager
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
