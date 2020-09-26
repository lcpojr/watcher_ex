defmodule Authenticator.SignIn.Inputs.ClientCredentials do
  @moduledoc """
  Input schema to be used in Client Credentials flow.
  """

  use Authenticator.Input

  @typedoc "Client credential flow input fields"
  @type t :: %__MODULE__{
          client_id: String.t(),
          client_secret: String.t(),
          grant_type: String.t(),
          scope: String.t()
        }

  @possible_grant_type ~w(client_credentials)

  @required [:client_id, :client_secret, :grant_type, :scope]
  embedded_schema do
    field :client_id, Ecto.UUID
    field :client_secret, :string
    field :grant_type, :string
    field :scope, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required)
    |> validate_length(:client_secret, min: 1)
    |> validate_inclusion(:grant_type, @possible_grant_type)
    |> validate_required(@required)
  end
end
