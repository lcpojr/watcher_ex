defmodule ResourceManager.Identity.Commands.Inputs.GetUser do
  @moduledoc """
  Input parameters for getting user identity
  """

  use ResourceManager.Input

  alias ResourceManager.Identity.Schemas.User

  @typedoc "Get user input fields"
  @type t :: %__MODULE__{
          username: String.t(),
          status: String.t()
        }

  @optional [:id, :username, :status]
  embedded_schema do
    field :id, Ecto.UUID
    field :username, :string
    field :status, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @optional)
    |> validate_length(:username, min: 1)
    |> validate_inclusion(:status, User.possible_statuses())
  end
end
