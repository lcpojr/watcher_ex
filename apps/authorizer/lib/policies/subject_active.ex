defmodule Authorizer.Policies.SubjectActive do
  @moduledoc """
  Authorization policy to ensure that an subject is active.
  """

  require Logger

  alias Authorizer.Ports.ResourceManager
  alias Plug.Conn

  @behaviour Authorizer.Policies.Behaviour

  @subject_types ~w(user application)

  @impl true
  def info do
    """
    Ensures that a specific subject is active.
    In order to succeed it has to have `status` set as `active`.
    """
  end

  @impl true
  def validate(%Conn{private: %{subject_id: subject_id, subject_type: subject_type} = context})
      when is_binary(subject_id) and subject_type in @subject_types,
      do: {:ok, context}

  def validate(_any), do: {:error, :invalid_session}

  @impl true
  def execute(context, _opts) when is_map(context) do
    with {:identity, {:ok, identity}} <- {:identity, get_identity(context)},
         {:active?, "active"} <- {:active?, identity.status} do
      Logger.debug("Policy #{__MODULE__} succeeded")
      :ok
    else
      {:identity, error} ->
        Logger.error("Policy #{__MODULE__} failed to get identity", error: inspect(error))
        {:error, :identity_not_found}

      {:active?, false} ->
        Logger.error("Policy #{__MODULE__} failed because subject is not active")
        {:error, :not_active}
    end
  end

  defp get_identity(%{subject_id: subject_id, subject_type: "user"}),
    do: ResourceManager.get_identity(%{id: subject_id, username: nil})

  defp get_identity(%{subject_id: subject_id, subject_type: "application"}),
    do: ResourceManager.get_identity(%{id: subject_id, client_id: nil})
end
