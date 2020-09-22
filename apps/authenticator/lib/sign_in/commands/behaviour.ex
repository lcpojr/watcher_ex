defmodule Authenticator.SignIn.Commands.Behaviour do
  @moduledoc "Behaviour definition for an Sign in flow"

  @typedoc "Token parameters to be sent on responses"
  @type token_params :: %{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_at: NaiveDateTime.t(),
          scope: String.t()
        }

  @typedoc "All possible responses"
  @type possible_responses ::
          {:ok, token_params()}
          | {:error, Ecto.Changeset.t() | :anauthenticated}

  @doc "Executes the sign in flow"
  @callback execute(input :: map()) :: possible_responses()
end
