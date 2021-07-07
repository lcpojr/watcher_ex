defmodule ResourceManager.Credentials.Schemas.Password do
  @moduledoc """
  User password credentials.

  We do not save raw passwords, only the encripted hash that will
  be used to authenticate.

  To see more about how we hash the password check `Argon2`.
  """

  use ResourceManager.Schema

  import Ecto.Changeset

  alias ResourceManager.Credentials.Commands.PasswordIsAllowed
  alias ResourceManager.Identities.Schemas.User

  @typedoc """
  Abstract password module type.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          user: User.t() | Ecto.Association.NotLoaded.t(),
          user_id: Ecto.UUID.t(),
          value: String.t() | nil,
          password_hash: String.t(),
          algorithm: String.t(),
          salt: integer(),
          inserted_at: NaiveDatetime.t(),
          updated_at: NaiveDatetime.t()
        }

  # Changeset validation arguments
  @acceptable_algorithms ~w(argon2 bcrypt pbkdf2)

  @required_fields [:password_hash]
  @optional_fields [:user_id, :value, :algorithm, :salt]
  schema "passwords" do
    field :value, :string, virtual: true, redact: true
    field :password_hash, :string
    field :algorithm, :string, default: "argon2"
    field :salt, :integer, default: 16

    belongs_to(:user, User)

    timestamps()
  end

  @doc "Generates an `%Ecto.Changeset{}` to be used in insert operations"
  @spec changeset(params :: map()) :: Ecto.Changeset.t()
  def changeset(params) when is_map(params), do: changeset(%__MODULE__{}, params)

  @doc "Generates an `%Ecto.Changeset to be used in update operations."
  @spec changeset(model :: %__MODULE__{}, params :: map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = model, params) when is_map(params) do
    model
    |> cast(params, @optional_fields)
    |> validate_inclusion(:algorithm, @acceptable_algorithms)
    |> validate_length(:value, min: 6)
    |> validate_password()
    |> hash_password()
    |> validate_required(@required_fields)
  end

  defp validate_password(%Ecto.Changeset{valid?: true, changes: %{value: password}} = changeset) do
    if PasswordIsAllowed.execute(password) do
      changeset
    else
      add_error(changeset, :password, "password not allowed")
    end
  end

  defp validate_password(%Ecto.Changeset{} = changeset), do: changeset

  defp hash_password(
         %Ecto.Changeset{
           valid?: true,
           changes: %{value: password} = changes
         } = changeset
       )
       when is_binary(password) do
    # Getting configs from changes or defaults
    algorithm = Map.get(changes, :algorithm, "argon2")
    salt = Map.get(changes, :salt, 16)

    password_hash =
      case algorithm do
        "argon2" -> Argon2.hash_pwd_salt(password, salt_len: salt)
        "bcrypt" -> Bcrypt.hash_pwd_salt(password, salt_len: salt)
        "pbkdf2" -> Pbkdf2.hash_pwd_salt(password, salt_len: salt)
      end

    put_change(changeset, :password_hash, password_hash)
  end

  defp hash_password(%Ecto.Changeset{} = changeset), do: changeset

  @doc "Returns a list with all acceptable algorithms"
  @spec acceptable_algorithms() :: list(String.t())
  def acceptable_algorithms, do: @acceptable_algorithms
end
