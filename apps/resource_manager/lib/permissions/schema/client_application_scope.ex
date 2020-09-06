defmodule ResourceManager.Permissions.Schemas.ClientApplicationScope do
  @moduledoc """
  Defines the relation between a client application and many scope.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ResourceManager.Identity.Schemas.ClientApplication
  alias ResourceManager.Permissions.Schemas.Scope

  @typedoc "Client application scope schema fields"
  @type t :: %__MODULE__{
          client_application: ClientApplication.t(),
          scope: Scope.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required_fields [:client_application_id, :scope_id]
  @primary_key false
  schema "client_applications_scopes" do
    field :client_application_id, :binary_id, primary_key: true
    field :scope_id, :binary_id, primary_key: true

    belongs_to(:client_application, ClientApplication, define_field: false)
    belongs_to(:scope, Scope, define_field: false)

    timestamps()
  end

  @doc false
  def changeset_create(%__MODULE__{}, params) do
    %__MODULE__{}
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:scope_id)
    |> foreign_key_constraint(:client_application_id)
  end
end
