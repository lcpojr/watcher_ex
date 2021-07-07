defmodule ResourceManager.Identities.Commands.CreateUser do
  @moduledoc """
  Command for creating a new user identity.
  """

  require Logger

  alias ResourceManager.Identities.Commands.Inputs.CreateUser
  alias ResourceManager.Identities.Schemas.User
  alias ResourceManager.Identities.Users
  alias ResourceManager.Permissions.Commands.ConsentScope
  alias ResourceManager.Repo

  @typedoc "All possible responses"
  @type possible_response :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  @doc "Create a new identity with it's credentials"
  @spec execute(params :: CreateUser.t()) :: possible_response()
  def execute(%CreateUser{} = input) do
    Logger.debug("Creating new user identity")

    Repo.execute_transaction(fn ->
      with {:ok, %User{} = user} <- create_user(input),
           {:ok, _scopes} <- create_permission(user, input.permission) do
        Logger.debug("Succeeds in creating user", id: user.id)
        {:ok, user}
      else
        {:error, reason} = result ->
          Logger.error("Failed to create user", reason: reason)
          result
      end
    end)
  end

  def execute(params) when is_map(params) do
    params
    |> CreateUser.cast_and_apply()
    |> case do
      {:ok, %CreateUser{} = input} -> execute(input)
      error -> error
    end
  end

  defp create_user(input) do
    input
    |> CreateUser.cast_to_map()
    |> Users.create()
  end

  defp create_permission(user, %{scopes: scopes}) when is_list(scopes), do: ConsentScope.execute(user, scopes)
  defp create_permission(_user, _permission), do: {:ok, :ignore}
end
