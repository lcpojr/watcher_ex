defmodule ResourceManager.Credentials.Schemas.TOTP do
  @moduledoc """
  User time based one time password (TOTP) credentials.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Identities.Schemas.User

  @typedoc """
  Abstract totp module type.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          secret: String.t(),
          digits: integer(),
          period: integer(),
          issuer: String.t(),
          user: User.t() | Ecto.Association.NotLoaded.t(),
          user_id: Ecto.UUID.t(),
          inserted_at: Datetime.t(),
          updated_at: Datetime.t()
        }

  # Default totp values
  @default_digits 6
  @default_period_in_seconds 60
  @default_issuer "WatcherEx"

  # Changeset validation arguments
  @acceptable_digits [4, 6]
  @acceptable_period [30, 60]

  @optional_fields [:user_id, :secret, :digits, :period, :issuer]
  schema "totps" do
    field :secret, :string
    field :digits, :integer, default: @default_digits
    field :period, :integer, default: @default_period_in_seconds
    field :issuer, :string, default: @default_issuer

    belongs_to(:user, User)

    timestamps()
  end

  @doc "Generates an `%Ecto.Changeset{}` to be used in insert operations"
  @spec changeset(params :: map()) :: Ecto.Changeset.t()
  def changeset(params) when is_map(params), do: changeset(%__MODULE__{}, params)

  @doc "Generates an `%Ecto.Changeset to be used in update operations."
  @spec changeset(model :: __MODULE__.t(), params :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @optional_fields)
    |> validate_inclusion(:digits, @acceptable_digits)
    |> validate_inclusion(:period, @acceptable_period)
    |> generate_secret()
  end

  defp generate_secret(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp generate_secret(%Ecto.Changeset{changes: %{secret: secret}} = changeset)
       when is_binary(secret),
       do: changeset

  defp generate_secret(%Ecto.Changeset{} = changeset) do
    secret =
      :sha256
      |> :crypto.hmac(:crypto.strong_rand_bytes(9), @default_issuer)
      |> Base.encode32(padding: false)

    put_change(changeset, :secret, secret)
  end
end
