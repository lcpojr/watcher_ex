defmodule ResourceManager.Identities.Commands.Inputs.GetClientApplication do
  @moduledoc """
  Input parameters for getting user identity
  """

  use ResourceManager.Input

  alias ResourceManager.Identities.Schemas.ClientApplication

  @typedoc "Get user input fields"
  @type t :: %__MODULE__{
          name: String.t(),
          status: String.t(),
          protocol: String.t(),
          access_type: String.t()
        }

  @optional [:id, :client_id, :name, :status, :protocol, :access_type]
  embedded_schema do
    field :id, Ecto.UUID
    field :client_id, Ecto.UUID
    field :name, :string
    field :status, :string
    field :protocol, :string
    field :access_type, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @optional)
    |> validate_length(:name, min: 1)
    |> validate_inclusion(:status, ClientApplication.possible_statuses())
    |> validate_inclusion(:protocol, ClientApplication.possible_protocols())
    |> validate_inclusion(:access_type, ClientApplication.possible_access_types())
  end
end
