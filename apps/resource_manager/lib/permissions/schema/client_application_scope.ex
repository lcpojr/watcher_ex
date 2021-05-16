defmodule ResourceManager.Permissions.Schemas.ClientApplicationScope do
  @moduledoc """
  Defines the relation between a client application and many scope.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Identities.Schemas.ClientApplication
  alias ResourceManager.Permissions.Schemas.Scope

  @typedoc "Client application scope schema fields"
  @type t :: %__MODULE__{
          client_application: ClientApplication.t(),
          scope: Scope.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @unique_constraint :client_applications_scopes_client_application_id_scope_id_index

  @required_fields [:client_application_id, :scope_id]
  @primary_key false
  schema "client_applications_scopes" do
    field :client_application_id, :binary_id, primary_key: true
    field :scope_id, :binary_id, primary_key: true

    belongs_to(:client_application, ClientApplication, define_field: false)
    belongs_to(:scope, Scope, define_field: false)

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
    |> foreign_key_constraint(:client_application_id)
    |> unique_constraint(:client_application, name: @unique_constraint)
  end
end
