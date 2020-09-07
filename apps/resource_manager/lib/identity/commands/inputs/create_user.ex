defmodule ResourceManager.Identity.Commands.Inputs.CreateUser do
  @moduledoc """
  Input parameters for creating user identity
  """

  use ResourceManager.Input

  alias ResourceManager.Identity.Schemas.User

  @typedoc "Create user input fields"
  @type t :: %__MODULE__{
          username: String.t(),
          status: String.t(),
          password: String.t(),
          password_algorithm: String.t(),
          scopes: list(String.t()) | nil
        }

  @required [:username, :password, :algorithm]
  @optional [:scopes]
  embedded_schema do
    # Identity
    field :username, :string
    field :status, :string, default: "active"

    # Credentials
    field :password, :string
    field :password_algorithm, :string, default: "argon2"

    # Permissions
    field :scopes, {:array, :string}
  end

  @doc false
  def cast_and_apply(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_inclusion(:status, User.possible_statuses())
    |> validate_required(@required)
  end
end
