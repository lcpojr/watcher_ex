defmodule Authenticator.Authentication.Ports.GetIdentity do
  @moduledoc """
  Port to access Resource manager get by command
  """

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, identity :: struct()} | {:error, :not_found}

  @doc "Delegates to command execute/1"
  @spec execute(params :: map()) :: possible_responses()
  def execute(params), do: implementation().execute(input)

  defp implementation do
    :authenticator
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:command)
  end
end
