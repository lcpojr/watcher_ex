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
  @acceptable_assertion_types ~w(urn:ietf:params:oauth:client-assertion-type:jwt-bearer)

  @required [:client_id, :grant_type, :ip_address, :scope]
  @optional [:client_secret, :client_assertion, :client_assertion_type]
  embedded_schema do
    field :client_id, Ecto.UUID
    field :grant_type, :string
    field :scope, :string
    field :ip_address, :string

    # Application credentials
    field :client_secret, :string
    field :client_assertion, :string
    field :client_assertion_type, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @required ++ @optional)
    |> validate_length(:client_secret, min: 1)
    |> validate_inclusion(:grant_type, @possible_grant_type)
    |> validate_required(@required)
    |> validate_assertion_type()
    |> validate_assertion()
  end

  defp validate_assertion_type(%{changes: %{client_assertion_type: assertion_type}} = changeset) do
    if assertion_type in @acceptable_assertion_types do
      changeset
    else
      opts = [enum: [@acceptable_assertion_types]]
      add_error(changeset, :client_assertion_type, "invalid assertion type", opts)
    end
  end

  defp validate_assertion_type(changeset), do: changeset

  defp validate_assertion(%{changes: changes} = changeset) do
    case changes do
      %{client_assertion_type: _, client_assertion: _} ->
        changeset

      %{client_secret: _} ->
        changeset

      %{client_assertion_type: _} ->
        add_error(changeset, :client_assertion, "can't be blank", validation: :required)

      _any ->
        changeset
        |> add_error(:client_assertion, "can't be blank", validation: :required)
        |> add_error(:client_assertion_type, "can't be blank", validation: :required)
    end
  end
end
