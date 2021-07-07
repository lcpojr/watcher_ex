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
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  # Default totp values
  @default_digits 6
  @default_period_in_seconds 30
  @default_issuer "WatcherEx"

  # Changeset validation arguments
  @acceptable_digits [4, 6]
  @acceptable_period [30, 60]

  @required_fields [:user_id, :username]
  @optional_fields [:secret, :digits, :period, :issuer]
  schema "totps" do
    field :username, :string, virtual: true
    field :secret, :string, redact: true
    field :digits, :integer, default: @default_digits
    field :period, :integer, default: @default_period_in_seconds
    field :issuer, :string, default: @default_issuer
    field :otp_uri, :string, redact: true

    belongs_to(:user, User)

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
    |> validate_inclusion(:digits, @acceptable_digits)
    |> validate_inclusion(:period, @acceptable_period)
    |> generate_secret()
    |> generate_otp_uri()
  end

  defp generate_secret(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp generate_secret(%Ecto.Changeset{changes: %{secret: secret}} = changeset)
       when is_binary(secret),
       do: changeset

  defp generate_secret(%Ecto.Changeset{} = changeset) do
    secret = Base.encode32(:crypto.strong_rand_bytes(20), padding: false)
    put_change(changeset, :secret, secret)
  end

  defp generate_otp_uri(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp generate_otp_uri(%Ecto.Changeset{changes: %{otp_uri: otp_uri}} = changeset)
       when is_binary(otp_uri),
       do: changeset

  defp generate_otp_uri(%Ecto.Changeset{changes: changes} = changeset) do
    label =
      case changes do
        %{username: username} when is_binary(username) ->
          URI.encode("#{@default_issuer}:#{username}")

        _changes ->
          URI.encode(@default_issuer)
      end

    query =
      URI.encode_query([
        {:secret, Map.get(changes, :secret)},
        {:issuer, Map.get(changes, :issuer, @default_issuer)},
        {:digits, Map.get(changes, :digits, @default_digits)},
        {:period, Map.get(changes, :period, @default_period_in_seconds)},
        {:algorithm, "SHA1"}
      ])

    put_change(changeset, :otp_uri, "otpauth://totp/#{label}?#{query}")
  end
end
