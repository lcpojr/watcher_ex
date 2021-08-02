defmodule Authenticator.Sessions.Schemas.Session do
  @moduledoc """
  Access token sessions.

  An access token is a binary string that encapsulates identity
  session and is used in order to authenticates that the requester
  is someone who is able to access certain resources and do some
  actions.
  """

  use Authenticator.Schema

  import Ecto.Changeset

  @typedoc "Session schema fields"
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          jti: String.t(),
          type: String.t(),
          subject_id: String.t(),
          subject_type: String.t(),
          claims: map(),
          status: String.t(),
          expires_at: NaiveDateTime.t(),
          grant_flow: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @possible_types ~w(access_token refresh_token)
  @possible_statuses ~w(active expired revoked refreshed)
  @possible_subject_types ~w(user application)
  @possible_grant_flows ~w(client_credentials resource_owner refresh_token)

  @required_fields [:jti, :type, :subject_id, :subject_type, :claims, :expires_at, :grant_flow]
  @optional_fields [:status]
  schema "sessions" do
    field :jti, :string
    field :type, :string
    field :subject_id, :string
    field :subject_type, :string
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
    |> validate_inclusion(:type, @possible_types)
    |> validate_inclusion(:status, @possible_statuses)
    |> validate_inclusion(:subject_type, @possible_subject_types)
    |> validate_inclusion(:grant_flow, @possible_grant_flows)
    |> validate_required(@required_fields)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @optional_fields)
    |> validate_inclusion(:status, @possible_statuses)
  end

  @doc false
  def possible_types, do: @possible_types

  @doc false
  def possible_statuses, do: @possible_statuses

  @doc false
  def possible_subject_types, do: @possible_subject_types

  @doc false
  def possible_grant_flows, do: @possible_grant_flows

  #################
  # Custom filters
  #################

  defp custom_query(query, {:ids, ids}), do: where(query, [c], c.id in ^ids)
  defp custom_query(query, {:created_after, date}), do: where(query, [c], c.inserted_at > ^date)
  defp custom_query(query, {:created_before, date}), do: where(query, [c], c.inserted_at < ^date)
  defp custom_query(query, {:expires_after, date}), do: where(query, [c], c.expires_at > ^date)
  defp custom_query(query, {:expires_before, date}), do: where(query, [c], c.expires_at < ^date)
end
