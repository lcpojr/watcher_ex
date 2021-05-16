defmodule ResourceManager.Permissions.Schemas.UserScope do
  @moduledoc """
  Defines the relation between a user and many scope.
  """

  use ResourceManager.Schema

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

  @unique_constraint :users_scopes_user_id_scope_id_index

  @required_fields [:user_id, :scope_id]
  @primary_key false
  schema "users_scopes" do
    field :user_id, :binary_id, primary_key: true
    field :scope_id, :binary_id, primary_key: true

    belongs_to :user, User, define_field: false
    belongs_to :scope, Scope, define_field: false

    timestamps()
  end

  @doc "Generates an `%Ecto.Changeset{}` to be used in insert operations"
  @spec changeset(params :: map()) :: Ecto.Changeset.t()
  def changeset(params) when is_map(params), do: changeset(%__MODULE__{}, params)

  @doc "Generates an `%Ecto.Changeset to be used in update operations."
  @spec changeset(model :: __MODULE__.t(), params :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:scope_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: @unique_constraint)
  end

  #################
  # Custom filters
  #################

  defp custom_query(query, {:scope_id_in, scope_ids}),
    do: where(query, [c], c.scope_id in ^scope_ids)

  defp custom_query(query, {:blocked_after, date}),
    do: where(query, [c], c.blocked_until > ^date)

  defp custom_query(query, {:blocked_before, date}),
    do: where(query, [c], c.blocked_until < ^date)
end
