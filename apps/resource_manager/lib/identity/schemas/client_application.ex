defmodule ResourceManager.Identity.Schemas.ClientApplication do
  @moduledoc """
  The application is a resource and a subject that makes requests through the systems.

  We do not save application private keys, only the public one.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Credentials.Schemas.PublicKey
  alias ResourceManager.Permissions.Schemas.Scope

  @typedoc "User schema fields"
  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          description: String.t(),
          status: String.t(),
          protocol: String.t(),
          access_type: String.t(),
          direct_access_grant_enabled: boolean(),
          service_account_enabled: boolean(),
          public_key: PublicKey.t(),
          scopes: Scope.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @possible_statuses ~s(active, inactive, blocked)
  @possible_protocols ~s(openid-connect)
  @possible_access_types ~s(cofidential)

  @required_fields [
    :name,
    :status,
    :protocol,
    :access_type,
    :direct_access_grant_enabled,
    :service_account_enabled
  ]

  @optional_fields [:description]

  schema "client_applications" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "active"
    field :protocol, :string, default: "openid-connect"
    field :access_type, :string, default: "confidential"
    field :direct_access_grant_enabled, :boolean, default: false
    field :service_account_enabled, :boolean, default: false

    has_one :public_key, PublicKey
    many_to_many :scopes, Scope, join_through: "client_applications_scopes"

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 150)
    |> validate_inclusion(:status, @possible_statuses)
    |> validate_inclusion(:protocol, @possible_protocols)
    |> validate_inclusion(:access_type, @possible_access_types)
    |> unique_constraint(:name)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_length(:name, min: 1, max: 150)
    |> validate_inclusion(:status, @possible_statuses)
    |> validate_inclusion(:protocol, @possible_protocols)
    |> validate_inclusion(:access_type, @possible_access_types)
    |> unique_constraint(:name)
  end

  @doc false
  def possible_statuses, do: @possible_statuses

  @doc false
  def possible_protocols, do: @possible_protocols

  @doc false
  def possible_access_types, do: @possible_access_types
end
