defmodule ResourceManager.Identity.Commands.CreateIdentity do
  @moduledoc """
  Command for creating a new identity.
  """

  require Logger

  alias Ecto.Multi
  alias ResourceManager.Permissions.Commands.ConsentScope
  alias ResourceManager.Credentials.{Passwords, PublicKeys}
  alias ResourceManager.Identity.Commands.Inputs.{CreateClientApplication, CreateUser}
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}
  alias ResourceManager.Identity.{ClientApplications, Users}
  alias ResourceManager.Repo

  @typedoc "All possible identities"
  @type identities :: User.t() | ClientApplication.t()

  @typedoc "All possible inputs"
  @type input :: CreateUser.t() | CreateClientApplication.t() | map()

  @typedoc "All possible responses"
  @type possible_response :: {:ok, identities()} | {:error, Ecto.Changeset.t()}

  @doc "Create a new identity with it's credentials"
  @spec execute(params :: input()) :: possible_response()
  def execute(%CreateUser{} = input) do
    Logger.info("Creating new user identity")

    Multi.new()
    |> Multi.run(:create_identity, fn _repo, _changes ->
      input
      |> CreateUser.cast_to_map()
      |> Users.create()
    end)
    |> Multi.run(:create_credential, fn _repo, %{create_identity: %User{} = user} ->
      user
      |> build_credential(input)
      |> Passwords.create()
    end)
    |> Multi.run(:create_permission, fn _repo, %{create_identity: %User{} = user} ->
      ConsentScope.execute(user, input.scopes)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_identity: %User{} = user}} ->
        Logger.info("Succeeds in creating user", id: user.id)
        {:ok, user}

      {:error, step, reason, _changes} ->
        Logger.error("Failed to create user in step #{inspect(step)}", reason: reason)
        {:error, reason}
    end
  end

  def execute(%CreateClientApplication{} = input) do
    Logger.info("Creating new client application identity")

    Multi.new()
    |> Multi.run(:create_identity, fn _repo, _changes ->
      input
      |> CreateClientApplication.cast_to_map()
      |> ClientApplications.create()
    end)
    |> Multi.run(:create_credential, fn _repo, %{create_identity: %ClientApplication{} = app} ->
      app
      |> build_credential(input)
      |> PublicKeys.create()
    end)
    |> Multi.run(:create_permission, fn _repo, %{create_identity: %ClientApplication{} = app} ->
      ConsentScope.execute(app, input.scopes)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_identity: %ClientApplication{} = app}} ->
        Logger.info("Succeeds in creating client application", id: app.id)
        {:ok, app}

      {:error, step, err, _changes} ->
        Logger.error("Failed to create client application in step #{inspect(step)}", reason: err)
        {:error, err}
    end
  end

  def execute(%{username: _, password: _} = params) do
    params
    |> CreateUser.cast_and_apply()
    |> case do
      {:ok, %CreateUser{} = input} -> execute(input)
      error -> error
    end
  end

  def execute(%{name: _, public_key: _} = params) do
    params
    |> CreateClientApplication.cast_and_apply()
    |> case do
      {:ok, %CreateClientApplication{} = input} -> execute(input)
      error -> error
    end
  end

  defp build_credential(%User{} = user, %{password: password, password_algorithm: algorithm}),
    do: %{user_id: user.id, password_hash: hash_password(password, algorithm)}

  defp build_credential(
         %ClientApplication{} = client_application,
         %{public_key: value, public_key_type: type, public_key_format: format}
       ) do
    %{
      client_application_id: client_application.id,
      value: value,
      type: type,
      format: format
    }
  end

  defp hash_password(password, "argon2"), do: Argon2.hash_pwd_salt(password)
end
