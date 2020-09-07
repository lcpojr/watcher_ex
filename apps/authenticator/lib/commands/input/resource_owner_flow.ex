defmodule Authenticator.Commands.Input.ResourceOwnerFlow do
  @moduledoc """
  Input parameter for resource owner authentication flow
  """

  use ResourceManager.Input

  @typedoc "Resource owner flow input type"
  @type t :: %__MODULE__{
          client_id: String.t(),
          client_secret: String.t(),
          scope: String.t(),
          username: String.t(),
          password: String.t(),
          grant_type: String.t()
        }

  @required [:client_id, :client_secret, :scope, :username, :password, :grant_type]
  embedded_schema do
    field(:client_id, Ecto.UUID)
    field(:client_secret, :string)
    field(:scope, :string)
    field(:username, :string)
    field(:password, :string)
    field(:grant_type, :string)
  end

  @doc false
  def cast_and_apply(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required)
    |> validate_length(:client_secret, min: 1)
    |> validate_length(:scope, min: 1)
    |> validate_length(:username, min: 1)
    |> validate_length(:password, min: 1)
    |> validate_inclusion(:grant_type, ~s(password))
    |> validate_required(@required)
  end
end
