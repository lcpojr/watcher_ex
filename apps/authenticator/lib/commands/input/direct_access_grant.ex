defmodule Authenticator.Commands.Input.DirectAccessGrant do
  @moduledoc """
  Input parameter for direct access grant flow
  """

  use ResourceManager.Input

  @typedoc "Create client application input fields"
  @type t :: %__MODULE__{
          client_id: String.t(),
          client_secret: String.t(),
          grant_type: String.t(),
          client_assertion: String.t(),
          client_assertion_type: String.t(),
          scope: String.t()
        }
end
