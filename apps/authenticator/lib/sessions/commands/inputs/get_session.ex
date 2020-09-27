defmodule Authenticator.Sessions.Commands.Inputs.GetSession do
  @moduledoc """
  Input parameters for getting a session
  """

  use Authenticator.Input

  alias Authenticator.Sessions.Schemas.Session

  @typedoc "Get user input fields"
  @type t :: %__MODULE__{
          id: String.t(),
          jti: String.t(),
          subject_id: String.t(),
          subject_type: String.t(),
          status: String.t(),
          grant_flow: String.t()
        }

  @optional [:id, :jti, :subject_id, :subject_type, :status, :grant_flow]
  embedded_schema do
    field :id, Ecto.UUID
    field :jti, :string
    field :subject_id, :string
    field :subject_type, :string
    field :status, :string
    field :grant_flow, :string
  end

  @doc false
  def changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @optional)
    |> validate_inclusion(:status, Session.possible_statuses())
    |> validate_inclusion(:subject_type, Session.possible_subject_types())
    |> validate_inclusion(:grant_flow, Session.possible_grant_flows())
    |> validate_emptiness()
  end

  defp validate_emptiness(%{valid?: false} = changeset), do: changeset
  defp validate_emptiness(%{changes: chg} = changeset) when map_size(chg) > 0, do: changeset
  defp validate_emptiness(changeset), do: add_error(changeset, :jti, "All input fields are empty")
end
