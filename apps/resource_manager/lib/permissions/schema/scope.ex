defmodule ResourceManager.Permissions.Schemas.Scope do
  @moduledoc """
  Defines all scopes that a subject can have.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Identities.Schemas.User

  @typedoc "Abstract scope module type."
  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          description: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required [:name]
  @optional [:description]
  schema "scopes" do
    field :name, :string
    field :description, :string

    many_to_many :users, User, join_through: "user_scope"

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:name, min: 1)
    |> unique_constraint(:name)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required ++ @optional)
    |> validate_length(:name, min: 1)
    |> unique_constraint(:name)
  end
end
