defmodule ResourceManager.Commands.Inputs.CreateUser do
  @moduledoc """
  Input parameters for creating user
  """

  use ResourceManager.Input

  alias ResourceManager.Identity.Schemas.User

  @typedoc "Create user input fields"
  @type t :: %__MODULE__{
          username: String.t(),
          password: String.t(),
          status: String.t() | nil,
          scopes: list(String.t()) | nil
        }

  @required [:username, :password]
  @optional [:status, :scopes]
  embedded_schema do
    field :username, :string
    field :password, :string
    field :status, :string
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
