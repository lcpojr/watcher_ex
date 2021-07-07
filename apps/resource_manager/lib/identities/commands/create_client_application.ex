defmodule ResourceManager.Identities.Commands.CreateClientApplication do
  @moduledoc """
  Command for creating a new client application identity.
  """

  require Logger

  alias ResourceManager.Identities.ClientApplications
  alias ResourceManager.Identities.Commands.Inputs.CreateClientApplication
  alias ResourceManager.Identities.Schemas.ClientApplication
  alias ResourceManager.Permissions.Commands.ConsentScope
  alias ResourceManager.Repo

  @typedoc "All possible responses"
  @type possible_response :: {:ok, ClientApplication.t()} | {:error, Ecto.Changeset.t()}

  @doc "Create a new identity with it's credentials"
  @spec execute(params :: CreateClientApplication.t()) :: possible_response()
  def execute(%CreateClientApplication{} = input) do
    Logger.debug("Creating new client application identity")

    Repo.execute_transaction(fn ->
      with {:ok, %ClientApplication{} = app} <- create_application(input),
           {:ok, _scopes} <- create_permission(app, input.permission) do
        Logger.debug("Succeeds in creating client application", id: app.id)
        {:ok, app}
      else
        {:error, reason} = result ->
          Logger.error("Failed to create client application", reason: reason)
          result
      end
    end)
  end

  def execute(params) when is_map(params) do
    params
    |> CreateClientApplication.cast_and_apply()
    |> case do
      {:ok, %CreateClientApplication{} = input} -> execute(input)
      error -> error
    end
  end

  defp create_application(input) do
    input
    |> CreateClientApplication.cast_to_map()
    |> ClientApplications.create()
  end

  defp create_permission(client_application, %{scopes: scopes}) when is_list(scopes),
    do: ConsentScope.execute(client_application, scopes)

  defp create_permission(_client_application, _permission), do: {:ok, :ignore}
end
