defmodule ResourceManager.Identities.Ports.GetTemporarillyBlocked do
  @moduledoc """
  Port to access Authenticator get temporarilly blocked command.
  """

  @doc "Delegates to #{__MODULE__}.execute/1 command"
  @callback execute(subject_type :: :user | :application) :: false

  @doc "Gets the temporarilly blocked subjects"
  @spec execute(subject_type :: :user | :application) :: false
  def execute(subject_type), do: implementation().execute(subject_type)

  defp implementation do
    :resource_manager
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
