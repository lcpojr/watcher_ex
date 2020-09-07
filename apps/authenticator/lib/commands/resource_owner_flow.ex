defmodule Authenticator.ResourceOwnerFlow do
  @moduledoc false

  alias Authenticator.Commands.Input.ResourceOwnerFlow

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, access_token :: String.t()} | {:error, atom()}

  @spec execute(input :: ResourceOwnerFlow.t()) :: possible_responses()
  def execute(%ResourceOwnerFlow{} = input) do
  end
end
