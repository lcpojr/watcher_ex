defmodule ResourceManager.Identity.Commands.Inputs.CreateClientApplication do
  @moduledoc """
  Input parameters for creating client applications
  """

  use ResourceManager.Input

  alias ResourceManager.Identity.Schemas.ClientApplication

  @typedoc "Create client application input fields"
  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          public_key: String.t(),
          public_key_type: String.t(),
          public_key_format: String.t(),
          status: String.t() | nil,
          protocol: String.t() | nil,
          access_type: String.t() | nil,
          scopes: list(String.t()) | nil
        }

  @required [:name, :public_key, :status, :protocol, :access_type]
  @optional [:description, :scopes]
  embedded_schema do
    # Identity
    field :name, :string
    field :description, :string
    field :status, :string, default: "active"
    field :protocol, :string, default: "openid-connect"
    field :access_type, :string, default: "confidential"
    field :grant_flows, {:array, :string}

    # Credentials
    field :public_key, :string
    field :public_key_type, :string, default: "rsa"
    field :public_key_format, :string, default: "pem"

    # Permissions
    field :scopes, {:array, :string}
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_length(:name, min: 1)
    |> validate_length(:public_key, min: 1)
    |> validate_inclusion(:status, ClientApplication.possible_statuses())
    |> validate_inclusion(:protocol, ClientApplication.possible_protocols())
    |> validate_inclusion(:grant_flows, ClientApplication.possible_grant_flows())
    |> validate_inclusion(:access_type, ClientApplication.possible_access_types())
    |> validate_required(@required)
  end
end
