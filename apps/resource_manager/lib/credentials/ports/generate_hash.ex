defmodule ResourceManager.Credentials.Ports.GenerateHash do
  @moduledoc """
  Port to access Authenticator generate hash command.
  """

  @typedoc "All possible hash algorithms"
  @type algorithms :: :argon2 | :bcrypt | :pbkdf2

  @doc "Delegates to #{__MODULE__}.execute/2 command"
  @callback execute(secret :: map() | String.t(), algorithm :: algorithms()) :: String.t()

  @doc "Delegates execution to hash secret command"
  @spec execute(secret :: String.t(), algorithm :: algorithms()) :: String.t()
  def execute(secret, algorithm \\ :argon2), do: implementation().execute(secret, algorithm)

  defp implementation do
    :resource_manager
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
