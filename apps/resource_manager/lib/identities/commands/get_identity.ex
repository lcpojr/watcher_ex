defmodule ResourceManager.Identities.Commands.GetIdentity do
  @moduledoc """
  Find out an identity that matches the given parameters
  """

  require Logger

  alias ResourceManager.Identities.{ClientApplications, Users}
  alias ResourceManager.Identities.Commands.Inputs.{GetClientApplication, GetUser}
  alias ResourceManager.Identities.Schemas.{ClientApplication, User}
  alias ResourceManager.Repo

  @typedoc "All possible identities"
  @type identities :: User.t() | ClientApplication.t()

  @typedoc "All possible inputs"
  @type input :: GetUser.t() | GetClientApplication.t() | map()

  @typedoc "All possible responses"
  @type possible_responses :: {:ok, identities()} | {:error, :not_found | :invalid_params}

  @doc "Returns an user or application identity seaching by the given input"
  @spec execute(params :: input()) :: possible_responses()
  def execute(%GetUser{} = input) do
    Logger.info("Getting user identity")

    input
    |> GetUser.cast_to_list()
    |> Users.get_by()
    |> Repo.preload([:password, :totp, :scopes])
    |> case do
      %User{} = user ->
        Logger.info("User identity #{user.id} got with success")
        {:ok, user}

      nil ->
        Logger.error("Failed to get user identity because it was not found")
        {:error, :not_found}
    end
  end

  def execute(%GetClientApplication{} = input) do
    Logger.info("Getting client application identity")

    input
    |> GetClientApplication.cast_to_list()
    |> ClientApplications.get_by()
    |> Repo.preload([:public_key, :scopes])
    |> case do
      %ClientApplication{} = client_application ->
        Logger.info("User identity #{client_application.id} got with success")
        {:ok, client_application}

      nil ->
        Logger.error("Failed to get client application identity because it was not found")
        {:error, :not_found}
    end
  end

  def execute(%{username: _} = params) do
    params
    |> GetUser.cast_and_apply()
    |> case do
      {:ok, %GetUser{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(%{client_id: _} = params) do
    params
    |> GetClientApplication.cast_and_apply()
    |> case do
      {:ok, %GetClientApplication{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(_any), do: {:error, :invalid_params}
end
