defmodule Authorizer.Rules.Commands.PublicAccess do
  @moduledoc """
  Rule for authorizing a subject to do any action on public endpoints.

  In order to authorize we have to execute an verification if the subject matches some
  requirements as:
    - It is status is active;
  """

  require Logger

  alias Authorizer.Policies.SubjectActive
  alias Plug.Conn

  @steps [SubjectActive]

  @doc """
  Run the authorization flow in order to verify if the subject matches all requirements.
  This will call the following policies:
    - #{SubjectActive};
  """
  @spec execute(conn :: Conn.t()) :: :ok | {:error, :unauthorized}
  def execute(%Conn{} = conn) do
    @steps
    |> Enum.reduce_while([], fn policy, opts -> run_policy(policy, conn, opts) end)
    |> case do
      {:error, :unauthorized} ->
        Logger.error("Failed on some of the policies")
        {:error, :unauthorized}

      _success ->
        :ok
    end
  end

  defp run_policy(policy, conn, opts) do
    with {:ok, context} <- policy.validate(conn),
         {:ok, shared_context} <- policy.execute(context, opts) do
      {:cont, shared_context}
    else
      error -> {:halt, error}
    end
  end
end
