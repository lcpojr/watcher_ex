defmodule Authenticator.Authentication.Commands.ResourceOwnerFlow do
  @moduledoc false

  alias Authenticator.Authentication.Commands.Input.ResourceOwnerFlow

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, access_token :: String.t()} | {:error, atom()}

  @spec execute(input :: ResourceOwnerFlow.t()) :: possible_responses()
  def execute(%ResourceOwnerFlow{} = input) do
    :ok
  end
end
