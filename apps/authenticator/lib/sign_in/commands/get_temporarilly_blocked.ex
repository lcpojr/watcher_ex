defmodule Authenticator.SignIn.Commands.GetTemporarillyBlocked do
  @moduledoc """
  Get subject authentication attempts that failed consecutively and return
  it's username or client_id.
  """

  require Logger

  alias Authenticator.SignIn.{ApplicationAttempts, UserAttempts}

  # Maximum failed attempts before block
  @max_attempts 5

  # 10 minutes interval
  @max_interval 60 * 10 * -1

  @doc """
  Return the identities that failed more than #{@max_attempts} times on sign in
  in #{@max_interval} seconds.
  """
  @spec execute(identity_type :: :user | :application) :: {:ok, list(String.t())}
  def execute(:user), do: {:ok, UserAttempts.list(get_filters())}
  def execute(:application), do: {:ok, ApplicationAttempts.list(get_filters())}

  # Query filters
  defp get_filters, do: [temporarilly_blocked: {@max_attempts, created_after()}]

  defp created_after do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(@max_interval, :second)
  end
end
