defmodule ResourceManager.Identities.Commands.Inputs.CreateUser do
  @moduledoc """
  Input parameters for creating user identity
  """

  use ResourceManager.Input

  alias ResourceManager.Identities.Schemas.User

  @typedoc "Create user input fields"
  @type t :: %__MODULE__{
          username: String.t(),
          status: String.t(),
          password_hash: String.t(),
          password_algorithm: String.t(),
          scopes: list(String.t()) | nil
        }

  @required [:username, :password_hash, :password_algorithm]
  @optional [:scopes]
  embedded_schema do
    # Identities
    field :username, :string
    field :status, :string, default: "active"

    # Credentials
    field :password_hash, :string
    field :password_algorithm, :string, default: "argon2"

    # Permissions
    field :scopes, {:array, :string}
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_length(:username, min: 1)
    |> validate_length(:password_hash, min: 1)
    |> validate_length(:password_algorithm, min: 1)
    |> validate_inclusion(:status, User.possible_statuses())
    |> validate_required(@required)
  end
end
