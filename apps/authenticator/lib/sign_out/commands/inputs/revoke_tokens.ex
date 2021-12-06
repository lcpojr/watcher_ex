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

  @optional [:access_token, :refresh_token]
  embedded_schema do
    field :access_token, :string
    field :refresh_token, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @optional)
    |> validate_at_least_one_token_required()
  end

  defp validate_at_least_one_token_required(%Ecto.Changeset{changes: changes} = changeset)
       when not is_map_key(changeset, :access_token) and not is_map_key(changes, :refresh_token) do
    changeset
    |> add_error(:access_token, "at least one token is required")
    |> add_error(:refresh_token, "at least one token is required")
  end

  defp validate_at_least_one_token_required(changeset), do: changeset
end
