defmodule Authenticator.SignIn.Schemas.UserAttempt do
  @moduledoc """
  User login attempts.

  Every time a user sign in on API we save the login attempt in order
  to create some rules to detect and prevant attacks.
  """

  use Authenticator.Schema

  import Ecto.Changeset

  @typedoc "User attempt schema fields"
  @type t :: %__MODULE__{
          id: binary(),
          username: String.t(),
          was_successful: boolean(),
          ip_address: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required_fields [:username, :was_successful, :ip_address]
  schema "user_sign_in_attempt" do
    field :username, :string
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
