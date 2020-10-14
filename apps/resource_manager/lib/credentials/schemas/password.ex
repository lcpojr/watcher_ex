defmodule ResourceManager.Credentials.Schemas.Password do
  @moduledoc """
  User password credentials.

  We do not save raw passwords, only the encripted hash that will
  be used to authenticate.

  To see more about how we hash the password check `Argon2`.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Identities.Schemas.User

  @typedoc """
  Abstract password module type.
  """
  @type t :: %__MODULE__{
          id: binary(),
          user: User.t(),
          algorithm: String.t(),
          password_hash: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @possible_algorithms ~w(argon2 bcrypt pbkdf2)

  @required_fields [:password_hash]
  @foreign_key_fields [:user_id]
  @optional_fields [:algorithm]
  schema "passwords" do
    field :password_hash, :string
    field :algorithm, :string, default: "argon2"

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset_create(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required_fields ++ @foreign_key_fields ++ @optional_fields)
    |> validate_required(@required_fields ++ @foreign_key_fields)
    |> validate_inclusion(:algorithm, @possible_algorithms)
    |> unique_constraint(:user_id)
  end

  @doc false
  def changeset_update(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_inclusion(:algorithm, @possible_algorithms)
    |> validate_required(@required_fields)
  end
end
