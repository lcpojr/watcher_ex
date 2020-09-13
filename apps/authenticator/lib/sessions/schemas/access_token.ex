defmodule Authenticator.Sessions.Schemas.AccessToken do
  @moduledoc """
  Access token sessions.

  An access token is a binary string that encapsulates identity
  session and is used in order to authenticates that the requester
  is someone who is able to access certain resources and do some
  actions.
  """

  use Authenticator.Schema

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
  schema "access_tokens" do
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
    |> cast(params, @optional_fields)
    |> validate_inclusion(:status, @possible_statuses)
  end

  @doc false
  def possible_statuses, do: @possible_statuses
end
