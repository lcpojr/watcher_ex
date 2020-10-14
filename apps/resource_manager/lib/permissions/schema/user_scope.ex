defmodule ResourceManager.Permissions.Schemas.UserScope do
  @moduledoc """
  Defines the relation between a user and many scope.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ResourceManager.Identities.Schemas.User
  alias ResourceManager.Permissions.Schemas.Scope

  @typedoc "User scope schema fields"
  @type t :: %__MODULE__{
          user_id: String.t(),
          scope_id: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required_fields [:user_id, :scope_id]
  @primary_key false
  schema "users_scopes" do
    field :user_id, :binary_id, primary_key: true
    field :scope_id, :binary_id, primary_key: true

    belongs_to :user, User, define_field: false
    belongs_to :scope, Scope, define_field: false

    timestamps()
  end

  @doc false
  def changeset_create(%__MODULE__{}, params) do
    %__MODULE__{}
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:scope_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :users_scopes_user_id_scope_id_index)
  end
end
