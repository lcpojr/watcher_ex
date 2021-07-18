defmodule Authorizer.Rules.Commands.Inputs.AuthorizationCodeSignIn do
  @moduledoc """
  Input schema to be used in sign in authorizations.
  """

  use Authorizer.Input

  @typedoc "Sign in authorization input fields"
  @type t :: %__MODULE__{
          client_id: String.t(),
          response_type: String.t(),
          redirect_uri: String.t() | nil,
          scope: String.t()
        }

  @possible_response_type ~w(code)

  @required [:client_id, :response_type, :scope, :state, :authorized]
  @optional [:redirect_uri]
  embedded_schema do
    field :client_id, :string
    field :response_type, :string
    field :redirect_uri, :string
    field :scope, :string
    field :state, :string
    field :authorized, :boolean
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_inclusion(:response_type, @possible_response_type)
    |> validate_length(:client_id, min: 1)
    |> validate_required(@required)
  end
end
