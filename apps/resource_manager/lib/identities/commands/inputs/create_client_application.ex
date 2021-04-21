defmodule ResourceManager.Identities.Commands.Inputs.CreateClientApplication do
  @moduledoc """
  Input parameters for creating client applications
  """

  use ResourceManager.Input

  alias ResourceManager.Credentials.Schemas.PublicKey
  alias ResourceManager.Identities.Schemas.ClientApplication

  @typedoc "Create client application input fields"
  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          status: String.t() | nil,
          protocol: String.t() | nil,
          access_type: String.t() | nil,
          credential: %{
            value: String.t(),
            type: String.t(),
            format: String.t()
          },
          permission: %{
            scopes: list(String.t()) | nil
          }
        }

  @required [:name, :status, :protocol, :access_type]
  @optional [:description]
  embedded_schema do
    # Identity
    field :name, :string
    field :description, :string
    field :status, :string, default: "active"
    field :protocol, :string, default: "openid-connect"
    field :access_type, :string, default: "confidential"
    field :grant_flows, {:array, :string}

    embeds_one :credential, Credential do
      field :value, :string
      field :type, :string, default: "rsa"
      field :format, :string, default: "pem"
    end

    embeds_one :permission, Permission do
      field :scopes, {:array, :string}
    end
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> cast_embed(:credential, with: &changeset_credential/2)
    |> cast_embed(:permission, with: &changeset_permission/2)
    |> validate_length(:name, min: 1)
    |> validate_inclusion(:status, ClientApplication.acceptable_statuses())
    |> validate_inclusion(:protocol, ClientApplication.acceptable_protocols())
    |> validate_inclusion(:grant_flows, ClientApplication.acceptable_grant_flows())
    |> validate_inclusion(:access_type, ClientApplication.acceptable_access_types())
    |> validate_required(@required)
  end

  defp changeset_credential(model, params) do
    model
    |> cast(params, [:value, :type, :format])
    |> validate_length(:value, min: 1)
    |> validate_inclusion(:type, PublicKey.acceptable_types())
    |> validate_inclusion(:format, PublicKey.acceptable_formats())
    |> validate_required([:value])
  end

  defp changeset_permission(model, params) do
    model
    |> cast(params, [:scopes])
    |> validate_required([:scopes])
  end
end
