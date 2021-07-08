defmodule ResourceManager.Identities.Manager do
  @moduledoc """
  Genserver for dealing with identity status changes.

  This will check for temporarilly blocked identities and update it's status
  when necessary.
  """

  use GenServer

  require Logger

  alias Ecto.Multi
  alias ResourceManager.Identities.Schemas.{ClientApplication, User}
  alias ResourceManager.Ports.Authenticator
  alias ResourceManager.Repo

  @typedoc "Identities manager supervisor state"
  @type state :: %{
          started_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t() | nil,
          scheduled_to: NaiveDateTime.t() | nil
        }

  # One minute interval
  @schedule_interval 60

  # 15 minutes in seconds
  @block_time 60 * 15

  #########
  # CLIENT
  #########

  # coveralls-ignore-start

  @doc "Starts the `GenServer"
  @spec start_link(args :: keyword()) :: {:ok, pid()} | :ignore | {:error, keyword()}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @doc "Checks GenServer actual state"
  @spec check(process_id :: pid() | __MODULE__) :: state()
  def check(pid \\ __MODULE__), do: GenServer.call(pid, :check)

  # coveralls-ignore-stop

  @doc "Update identity statuses and save on cache"
  @spec execute() :: {:ok, :managed} | {:error, :update_failed | :failed_to_cache}
  def execute, do: manage_identities()

  # coveralls-ignore-start

  @impl true
  def init(_args) do
    Logger.info("Identity manager started")

    state = %{
      started_at: NaiveDateTime.utc_now(),
      updated_at: nil,
      scheduled_to: nil
    }

    {:ok, state, {:continue, :manage}}
  end

  @impl true
  def handle_continue(:manage, state) do
    # Scheduling next management
    state = schedule_work(state)

    {:noreply, state}
  end

  @impl true
  def handle_call(:check, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info(:manage, state), do: {:noreply, state, {:continue, :manage}}

  # coveralls-ignore-stop

  ##########
  # Helpers
  ##########

  defp manage_identities do
    Multi.new()
    |> Multi.run(:get_user_identities, fn _repo, _changes ->
      Authenticator.get_temporarilly_blocked(:user)
    end)
    |> Multi.run(:block_user_identities, fn _repo, %{get_user_identities: usernames} ->
      block_user_identities(usernames)
    end)
    |> Multi.run(:unblock_user_identities, fn _repo, _changes ->
      unblock_user_identities()
    end)
    |> Multi.run(:get_application_identities, fn _repo, _changes ->
      Authenticator.get_temporarilly_blocked(:application)
    end)
    |> Multi.run(:block_application_identities, fn _, %{get_application_identities: client_ids} ->
      block_application_identities(client_ids)
    end)
    |> Multi.run(:unblock_application_identities, fn _repo, _changes ->
      unblock_application_identities()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _any} ->
        Logger.info("Succeeds in managing identities")
        {:ok, :managed}

      {:error, step, err, _changes} ->
        Logger.error("Failed to manage identities in step #{inspect(step)}", reason: err)
        {:error, err}
    end
  end

  defp block_user_identities(usernames) when is_list(usernames) do
    [usernames: usernames, status: "active"]
    |> User.query()
    |> Repo.update_all(
      set: [
        status: "temporary_blocked",
        blocked_until: blocked_until(),
        updated_at: NaiveDateTime.utc_now()
      ]
    )
    |> case do
      {count, _} when is_integer(count) ->
        Logger.debug("Identities manager blocked #{inspect(count)} user identities")
        {:ok, count}

      err ->
        Logger.error("Identities manager failed to block user identities", error: inspect(err))
        {:error, :update_failed}
    end
  end

  defp unblock_user_identities do
    [status: "temporary_blocked", blocked_before: NaiveDateTime.utc_now()]
    |> User.query()
    |> Repo.update_all(
      set: [
        status: "active",
        blocked_until: nil,
        updated_at: NaiveDateTime.utc_now()
      ]
    )
    |> case do
      {count, _} when is_integer(count) ->
        Logger.debug("Identities manager unblocked #{inspect(count)} user identities")
        {:ok, count}

      err ->
        Logger.error("Identities manager failed to unblocked user identities", error: inspect(err))

        {:error, :update_failed}
    end
  end

  defp block_application_identities(client_ids) when is_list(client_ids) do
    [client_ids: client_ids, status: "active"]
    |> ClientApplication.query()
    |> Repo.update_all(
      set: [
        status: "temporary_blocked",
        blocked_until: blocked_until(),
        updated_at: NaiveDateTime.utc_now()
      ]
    )
    |> case do
      {count, _} when is_integer(count) ->
        Logger.debug("Identities manager blocked #{inspect(count)} app identities")
        {:ok, count}

      err ->
        Logger.error("Identities manager failed to block app identities", error: inspect(err))
        {:error, :update_failed}
    end
  end

  defp unblock_application_identities do
    [status: "temporary_blocked", blocked_before: NaiveDateTime.utc_now()]
    |> ClientApplication.query()
    |> Repo.update_all(
      set: [
        status: "active",
        blocked_until: nil,
        updated_at: NaiveDateTime.utc_now()
      ]
    )
    |> case do
      {count, _} when is_integer(count) ->
        Logger.debug("Identities manager unblocked #{inspect(count)} app identities")
        {:ok, count}

      err ->
        Logger.error("Identities manager failed to unblocked app identities", error: inspect(err))
        {:error, :update_failed}
    end
  end

  defp blocked_until do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(@block_time, :second)
  end

  # coveralls-ignore-start

  defp schedule_work(state) do
    interval = schedule_interval()
    date_to_schedule = schedule_to(interval)

    Process.send_after(__MODULE__, :manage, :timer.seconds(interval))

    # Updating state
    %{state | scheduled_to: date_to_schedule}
  end

  defp schedule_to(interval) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(interval, :second)
    |> NaiveDateTime.truncate(:second)
  end

  defp schedule_interval, do: Keyword.get(config(), :schedule_interval, @schedule_interval)
  defp config, do: Application.get_env(:authenticator, __MODULE__, [])

  # coveralls-ignore-stop
end
