defmodule ResourceManager.Identities.Schemas.User do
  @moduledoc """
  The user is a resource and a subject that makes requests through the systems.

  We do not save users password, only the encripted hash that will
  be used to authenticate in password based forms.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Credentials.Schemas.Password
  alias ResourceManager.Permissions.Schemas.Scope

  @typedoc "User schema fields"
  @type t :: %__MODULE__{
          id: binary(),
          username: String.t(),
          status: String.t(),
          password: Password.t(),
          is_admin: boolean(),
          scopes: Scope.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @possible_statuses ~w(active inactive blocked temporary_blocked)

  @required_fields [:username, :status]
  @optional_fields [:blocked_until]
  schema "users" do
    field :username, :string
    field :status, :string, default: "active"
    field :is_admin, :boolean, default: false
    field :blocked_until, :naive_datetime

    has_one :password, Password
    many_to_many :scopes, Scope, join_through: "users_scopes"

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:username, min: 5, max: 150)
    |> validate_inclusion(:status, @possible_statuses)
    |> unique_constraint(:username)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_length(:username, min: 5, max: 150)
    |> validate_inclusion(:status, @possible_statuses)
    |> unique_constraint(:username)
  end

  @doc false
  def possible_statuses, do: @possible_statuses

  #################
  # Custom filters
  #################

  defp custom_query(query, {:usernames, usernames}),
    do: where(query, [c], c.username in ^usernames)

  defp custom_query(query, {:blocked_after, date}),
    do: where(query, [c], c.blocked_until > ^date)

  defp custom_query(query, {:blocked_before, date}),
    do: where(query, [c], c.blocked_until < ^date)
end
