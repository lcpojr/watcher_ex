defmodule ResourceManager.Credentials.Schemas.PublicKey do
  @moduledoc """
  Client application public key credentials.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Identities.Schemas.ClientApplication

  @typedoc """
  Abstract public_key module type.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          client_application: ClientApplication.t() | Ecto.Association.NotLoaded.t(),
          client_application_id: Ecto.UUID.t(),
          value: String.t(),
          type: String.t(),
          format: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  # Changeset validation arguments
  @acceptable_types ~w(rsa)
  @acceptable_formats ~w(pem)

  @required_fields [:value]
  @optional_fields [:client_application_id, :type, :format]
  schema "public_keys" do
    field :value, :string
    field :type, :string, default: "rsa"
    field :format, :string, default: "pem"

    belongs_to :client_application, ClientApplication

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
    |> validate_inclusion(:type, @acceptable_types)
    |> validate_inclusion(:format, @acceptable_formats)
    |> validate_required(@required_fields)
  end

  @doc "All acceptable public key types"
  @spec acceptable_types() :: list(String.t())
  def acceptable_types, do: @acceptable_types

  @doc "All acceptable public key formats"
  @spec acceptable_formats() :: list(String.t())
  def acceptable_formats, do: @acceptable_formats
end
