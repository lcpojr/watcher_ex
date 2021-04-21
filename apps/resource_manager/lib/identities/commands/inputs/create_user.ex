defmodule ResourceManager.Identities.Commands.Inputs.CreateUser do
  @moduledoc """
  Input parameters for creating user identity
  """

  use ResourceManager.Input

  alias ResourceManager.Credentials.Schemas.Password
  alias ResourceManager.Identities.Schemas.User

  @typedoc "Create user input fields"
  @type t :: %__MODULE__{
          username: String.t(),
          status: String.t(),
          password: %{
            value: String.t(),
            algorithm: String.t() | nil,
            salt: integer() | nil
          },
          permission: %{
            scopes: list(String.t()) | nil
          }
        }

  @required [:username]
  @optional [:status]
  embedded_schema do
    # Identity
    field :username, :string
    field :status, :string, default: "active"

    embeds_one :password, Credential, primary_key: false do
      field :value, :string
      field :algorithm, :string, default: "argon2"
      field :salt, :integer, default: 16
    end

    embeds_one :permission, Permission, primary_key: false do
      field :scopes, {:array, :string}
    end
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> cast_embed(:password, with: &changeset_password/2)
    |> cast_embed(:permission, with: &changeset_permission/2)
    |> validate_length(:username, min: 1)
    |> validate_inclusion(:status, User.acceptable_statuses())
    |> validate_required(@required)
  end

  defp changeset_password(model, params) do
    model
    |> cast(params, [:value, :algorithm, :salt])
    |> validate_length(:value, min: 6)
    |> validate_inclusion(:algorithm, Password.acceptable_algorithms())
    |> validate_required([:value])
  end

  defp changeset_permission(model, params) do
    model
    |> cast(params, [:scopes])
    |> validate_required([:scopes])
  end
end
