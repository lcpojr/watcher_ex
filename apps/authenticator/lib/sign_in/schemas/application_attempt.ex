defmodule Authenticator.SignIn.Schemas.ApplicationAttempt do
  @moduledoc """
  Application login attempts.

  Every time a application sign in on API we save the login attempt in order
  to create some rules to detect and prevant attacks.
  """

  use Authenticator.Schema

  import Ecto.Changeset

  @typedoc "Application attempt schema fields"
  @type t :: %__MODULE__{
          id: binary(),
          client_id: String.t(),
          was_successful: boolean(),
          ip_address: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required_fields [:client_id, :was_successful, :ip_address]
  schema "application_sign_in_attempt" do
    field :client_id, :string
    field :was_successful, :boolean
    field :ip_address, :string

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params),
    do: cast(model, params, @required_fields)

  #################
  # Custom filters
  #################

  defp custom_query(query, {:ids, ids}), do: where(query, [c], c.id in ^ids)
  defp custom_query(query, {:created_after, date}), do: where(query, [c], c.inserted_at > ^date)
  defp custom_query(query, {:created_before, date}), do: where(query, [c], c.inserted_at < ^date)
end
