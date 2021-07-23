defmodule Authenticator.SignOut.Commands.Inputs.RevokeTokens do
  @moduledoc """
  Input schema to be used in Revoke Tokens flow.
  """

  use Authenticator.Input

  @typedoc "Revoke Tokens flow input fields"
  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          refresh_token: String.t() | nil
        }

  @required [:access_token, :refresh_token]
  embedded_schema do
    field :access_token, :string
    field :refresh_token, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end
end