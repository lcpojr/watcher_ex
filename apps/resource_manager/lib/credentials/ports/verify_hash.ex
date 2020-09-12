defmodule ResourceManager.Credentials.Ports.VerifyHash do
  @moduledoc """
  Port to access Authenticator verify hash command.
  """

  @typedoc "All possible hash algorithms"
  @type algorithms :: :argon2 | :bcrypt | :pbkdf2

  @doc "Delegates to #{__MODULE__}.execute/2 command"
  @callback execute(
              secret :: String.t(),
              hash :: String.t(),
              algorithm :: algorithms()
            ) :: boolean()

  @doc "Delegates execution to hash secret command"
  @spec execute(secret :: String.t(), hash :: String.t(), algorithm :: algorithms()) :: String.t()
  def execute(secret, hash, algorithm \\ :argon2),
    do: implementation().execute(secret, hash, algorithm)

  defp implementation do
    :resource_manager
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
