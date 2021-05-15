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

  @default_algorithm "argon2"
  @default_salt 16
  @minimum_password_size 6

  @required [:username]
  @optional [:status]
  embedded_schema do
    # Identity
    field :username, :string
    field :status, :string, default: "active"

    embeds_one :password, Credential, primary_key: false do
      field :value, :string
      field :algorithm, :string, default: @default_algorithm
      field :salt, :integer, default: @default_salt
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
    |> validate_length(:value, min: @minimum_password_size)
    |> validate_inclusion(:algorithm, Password.acceptable_algorithms())
    |> validate_required([:value])
  end

  defp changeset_permission(model, params) do
    model
    |> cast(params, [:scopes])
    |> validate_required([:scopes])
  end
end
