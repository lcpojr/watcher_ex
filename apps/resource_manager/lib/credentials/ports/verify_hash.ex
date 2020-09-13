defmodule ResourceManager.Credentials.Ports.VerifyHash do
  @moduledoc """
  Port to access Authenticator verify hash command.
  """

  alias ResourceManager.Identity.Schemas.{ClientApplication, User}

  @typedoc "All possible hash algorithms"
  @type algorithms :: :argon2 | :bcrypt | :pbkdf2

  @doc "Delegates to #{__MODULE__}.execute/2 command"
  @callback execute(
              identity :: User.t() | ClientApplication.t(),
              secret :: String.t()
            ) :: boolean()

  @doc "Delegates to #{__MODULE__}.execute/3 command"
  @callback execute(
              secret :: String.t(),
              hash :: String.t() | nil,
              algorithm :: algorithms()
            ) :: boolean()

  @doc "Gets the hash and algorithm from the input and verifies if it matches the hash"
  @spec execute(identity :: map(), credential :: String.t()) :: boolean()
  def execute(entity, secret)
      when is_map(entity) and is_binary(secret),
      do: implementation().execute(entity, secret)

  @doc "Delegates execution to hash secret command"
  @spec execute(secret :: String.t(), hash :: String.t(), algorithm :: algorithms()) :: String.t()
  def execute(secret, hash, algorithm \\ :argon2)
      when is_binary(secret) and is_binary(hash) and is_atom(algorithm),
      do: implementation().execute(secret, hash, algorithm)

  defp implementation do
    :resource_manager
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
