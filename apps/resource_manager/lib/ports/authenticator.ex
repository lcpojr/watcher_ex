defmodule ResourceManager.Ports.Authenticator do
  @moduledoc """
  Port to access Authenticator domain commands.
  """

  @typedoc "All possible hash algorithms"
  @type algorithms :: :argon2 | :bcrypt | :pbkdf2

  @doc "Delegates to #{__MODULE__}.fake_verify_hash/1 command"
  @callback fake_verify_hash(algorithm :: algorithms()) :: false

  @doc "Delegates to #{__MODULE__}.generate_hash/2 command"
  @callback generate_hash(secret :: map() | String.t(), algorithm :: algorithms()) :: String.t()

  @doc "Delegates to #{__MODULE__}.get_temporarilly_blocked/1 command"
  @callback get_temporarilly_blocked(subject_type :: :user | :application) :: list(String.t())

  @doc "Gets the hash and algorithm from the input and verifies if it matches the hash"
  @spec fake_verify_hash(algorithm :: algorithms()) :: false
  def fake_verify_hash(algorithm), do: implementation().fake_verify_hash(algorithm)

  @doc "Delegates execution to generate hash command"
  @spec generate_hash(secret :: String.t(), algorithm :: algorithms()) :: String.t()
  def generate_hash(secret, algorithm \\ :argon2),
    do: implementation().generate_hash(secret, algorithm)

  @doc "Gets the temporarilly blocked subjects"
  @spec get_temporarilly_blocked(subject_type :: :user | :application) :: false
  def get_temporarilly_blocked(subject_type),
    do: implementation().get_temporarilly_blocked(subject_type)

  defp implementation do
    :resource_manager
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
