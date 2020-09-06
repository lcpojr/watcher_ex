defmodule ResourceManager.Credentials.Schemas.PublicKey do
  @moduledoc """
  Client application public key credentials.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Identity.Schemas.ClientApplication

  @typedoc """
  Abstract public_key module type.
  """
  @type t :: %__MODULE__{
          id: binary(),
          client_application: ClientApplication.t(),
          value: String.t(),
          type: String.t(),
          format: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @possible_types ~s(rsa)
  @possible_formats ~s(pem)

  @required_fields [:value]
  @foreign_key_fields [:client_application_id]
  @optional_fields [:type, :format]
  schema "public_keys" do
    field :value, :string
    field :type, :string, default: "rsa"
    field :format, :string, default: "pem"

    belongs_to :client_application, ClientApplication

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required_fields ++ @foreign_key_fields ++ @optional_fields)
    |> validate_required(@required_fields ++ @foreign_key_fields)
    |> validate_inclusion(:type, @possible_types)
    |> validate_inclusion(:format, @possible_formats)
    |> unique_constraint(:user_id)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_inclusion(:type, @possible_types)
    |> validate_inclusion(:format, @possible_formats)
    |> validate_required(@required_fields)
  end

  @doc false
  def possible_types, do: @possible_types

  @doc false
  def possible_formats, do: @possible_formats
end
