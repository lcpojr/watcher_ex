defmodule Authenticator.Sessions.Schemas.AccessToken do
  @moduledoc false

  use ResourceManager.Schema

  import Ecto.Changeset

  @typedoc "AccessToken schema fields"
  @type t :: %__MODULE__{
          id: binary(),
          jti: String.t(),
          claims: map(),
          status: String.t(),
          expires_at: NaiveDateTime.t(),
          grant_flow: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @possible_statuses ~w(active expired invalidated)

  @required_fields [:jti, :claims, :expires_at, :grant_flow]
  @optional_fields [:status]
  schema "sessions" do
    field :jti, :string
    field :claims, :map
    field :status, :string, default: "active"
    field :expires_at, :naive_datetime
    field :grant_flow, :string

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields)
    |> validate_inclusion(:status, @possible_statuses)
  end

  @doc false
  def possible_statuses, do: @possible_statuses
end
