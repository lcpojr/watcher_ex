defmodule Authenticator.SignIn.Inputs.RefreshToken do
  @moduledoc """
  Input schema to be used in Refresh Token flow.
  """

  use Authenticator.Input

  @typedoc "Refresh token flow input fields"
  @type t :: %__MODULE__{
          refresh_token: String.t(),
          grant_type: String.t()
        }

  @possible_grant_type ~w(refresh_token)

  @required [:refresh_token, :grant_type]
  embedded_schema do
    field :refresh_token, :string
    field :grant_type, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required)
    |> validate_length(:refresh_token, min: 1)
    |> validate_inclusion(:grant_type, @possible_grant_type)
    |> validate_required(@required)
  end
end
