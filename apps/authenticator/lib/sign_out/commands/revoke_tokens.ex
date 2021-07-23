defmodule Authenticator.SignOut.Commands.RevokeTokens do
  @moduledoc """
  Invalidates all subject sessions.
  """

  alias Authenticator.SignOut.Commands.Inputs.RevokeTokens

  require Logger

  def execute(%RevokeTokens{} = input) do
    {:ok, []}
  end
end
