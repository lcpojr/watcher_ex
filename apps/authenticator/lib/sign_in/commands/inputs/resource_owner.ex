defmodule Authenticator.SignIn.Inputs.ResourceOwner do
  @moduledoc """
  Input schema to be used in Resource Owner flow.
  """

  use Authenticator.Input

  @typedoc "Resource owner flow input fields"
  @type t :: %__MODULE__{
          username: String.t(),
          password: String.t(),
          grant_type: String.t(),
          scope: String.t(),
          client_id: String.t(),
          client_secret: String.t()
        }

  @possible_grant_type ~w(password)

  @required [:username, :password, :client_id, :client_secret, :scope, :grant_type]
  embedded_schema do
    field :username, :string
    field :password, :string
    field :grant_type, :string
    field :scope, :string
    field :client_id, :string
    field :client_secret, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required)
    |> validate_length(:username, min: 1)
    |> validate_length(:password, min: 1)
    |> validate_inclusion(:grant_type, @possible_grant_type)
    |> validate_length(:scope, min: 1)
    |> validate_length(:client_id, min: 1)
    |> validate_length(:client_secret, min: 1)
    |> validate_required(@required)
  end
end
