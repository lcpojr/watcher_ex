defmodule Authorizer.Policies.AdminAllowed do
  @moduledoc """
  Authorization policy to ensure that an subject is an admin.
  """

  require Logger

  alias Authorizer.Ports.ResourceManager
  alias Plug.Conn

  @behaviour Authorizer.Policies.Behaviour

  @subject_types ~w(user application)

  @impl true
  def info do
    """
    Ensures that a specific subject is allowed to do an admin action.
    In order to succeed it has to have `is_admin` set as `true`.
    """
  end

  @impl true
  def validate(%Conn{private: %{session: session}} = context) when is_map(session) do
    case session do
      %{subject_id: id, subject_type: type} when is_binary(id) and type in @subject_types ->
        Logger.debug("Policity #{__MODULE__} validated with success")
        {:ok, context}

      _any ->
        Logger.error("Policy #{__MODULE__} failed on validation because session is invalid")
        {:error, :unauthorized}
    end
  end

  def validate(%Conn{private: %{session: _}}) do
    Logger.error("Policy #{__MODULE__} failed on validation because session was not found")
    {:error, :unauthorized}
  end

  @impl true
  def execute(%Conn{private: %{session: session}}, opts \\ [])
      when is_map(session) and is_list(opts) do
    # We look for the identity on shared context first
    identity = Keyword.get(opts, :identity)

    with {:identity, {:ok, identity}} <- {:identity, get_identity(identity || session)},
         {:admin?, true} <- {:admin?, identity.is_admin} do
      Logger.debug("Policy #{__MODULE__} execution succeeded")
      {:ok, Keyword.put(opts, :identity, identity)}
    else
      {:identity, error} ->
        Logger.error("Policy #{__MODULE__} failed to get identity", error: inspect(error))
        {:error, :unauthorized}

      {:admin?, false} ->
        Logger.error("Policy #{__MODULE__} failed because subject is not an admin")
        {:error, :unauthorized}
    end
  end

  defp get_identity(%{subject_id: subject_id, subject_type: "user"}),
    do: ResourceManager.get_identity(%{id: subject_id, username: nil})

  defp get_identity(%{subject_id: subject_id, subject_type: "application"}),
    do: ResourceManager.get_identity(%{id: subject_id, client_id: nil})

  defp get_identity(%{status: _} = identity), do: {:ok, identity}
end
