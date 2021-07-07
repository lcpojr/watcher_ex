defmodule ResourceManager.Identities.Schemas.ClientApplication do
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
          id: Ecto.UUID.t(),
          client_id: String.t(),
          name: String.t(),
          description: String.t(),
          status: String.t(),
          protocol: String.t(),
          access_type: String.t(),
          is_admin: boolean(),
          grant_flows: list(String.t()),
          public_key: PublicKey.t() | Ecto.Association.NotLoaded.t(),
          scopes: Scope.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  # Changeset validation attributes
  @acceptable_statuses ~w(active inactive blocked)
  @acceptable_protocols ~w(openid-connect)
  @acceptable_access_types ~w(confidential public bearer-only)
  @acceptable_grant_flows ~w(resource_owner implicit client_credentials refresh_token authorization_code)

  @required_fields [:name, :status, :protocol, :access_type]
  @optional_fields [:grant_flows, :description, :redirect_uri, :blocked_until]
  schema "client_applications" do
    field :client_id, Ecto.UUID, autogenerate: true
    field :name, :string
    field :description, :string
    field :status, :string, default: "active"
    field :blocked_until, :naive_datetime
    field :protocol, :string, default: "openid-connect"
    field :access_type, :string, default: "public"
    field :is_admin, :boolean, default: false
    field :grant_flows, {:array, :string}
    field :redirect_uri, :string
    field :secret, :string

    has_one :public_key, PublicKey
    many_to_many :scopes, Scope, join_through: "client_applications_scopes"

    timestamps()
  end

  @doc "Generates an `%Ecto.Changeset{}` to be used in insert operations"
  @spec changeset(params :: map()) :: Ecto.Changeset.t()
  def changeset(params) when is_map(params), do: changeset(%__MODULE__{}, params)

  @doc "Generates an `%Ecto.Changeset to be used in update operations."
  @spec changeset(model :: %__MODULE__{}, params :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 150)
    |> validate_inclusion(:status, @acceptable_statuses)
    |> validate_inclusion(:protocol, @acceptable_protocols)
    |> validate_inclusion(:access_type, @acceptable_access_types)
    |> validate_subset(:grant_flows, @acceptable_grant_flows)
    |> unique_constraint(:name)
    |> generate_secret()
  end

  defp generate_secret(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp generate_secret(%Ecto.Changeset{valid?: true} = changeset) do
    secret = Bcrypt.hash_pwd_salt(Ecto.UUID.generate())
    put_change(changeset, :secret, secret)
  end

  @doc "All acceptable client application statuses"
  @spec acceptable_statuses() :: list(String.t())
  def acceptable_statuses, do: @acceptable_statuses

  @doc "All acceptable client application protocols"
  @spec acceptable_protocols() :: list(String.t())
  def acceptable_protocols, do: @acceptable_protocols

  @doc "All acceptable client application access types"
  @spec acceptable_access_types() :: list(String.t())
  def acceptable_access_types, do: @acceptable_access_types

  @doc "All acceptable client application grant flows"
  @spec acceptable_grant_flows() :: list(String.t())
  def acceptable_grant_flows, do: @acceptable_grant_flows

  #################
  # Custom filters
  #################

  defp custom_query(query, {:client_ids, client_ids}),
    do: where(query, [c], c.client_id in ^client_ids)

  defp custom_query(query, {:blocked_after, date}),
    do: where(query, [c], c.blocked_until > ^date)

  defp custom_query(query, {:blocked_before, date}),
    do: where(query, [c], c.blocked_until < ^date)
end
