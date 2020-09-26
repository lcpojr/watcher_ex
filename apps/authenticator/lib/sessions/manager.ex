defmodule Authenticator.Sessions.Manager do
  @moduledoc """
  GenServer for dealing with session expirations.
  """

  use GenServer

  require Logger

  alias Authenticator.Repo
  alias Authenticator.Sessions.Cache
  alias Authenticator.Sessions.Schemas.Session
  alias Ecto.Multi

  @typedoc "Session manager supervisor state"
  @type state :: %{
          started_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t() | nil,
          scheduled_to: NaiveDateTime.t() | nil
        }

  # Last five minutes
  @query_interval 60 * 5 * -1

  # One minute interval
  @schedule_interval 60

  #########
  # CLIENT
  #########

  # coveralls-ignore-start

  @doc "Starts the `GenServer"
  @spec start_link(args :: keyword()) :: {:ok, pid()} | :ignore | {:error, keyword()}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @doc "Checks #{__MODULE__} actual state"
  @spec check(process_id :: pid() | __MODULE__) :: state()
  def check(pid \\ __MODULE__), do: GenServer.call(pid, :check)

  # coveralls-ignore-stop

  @doc "Update session statuses and save on cache"
  @spec execute() :: {:ok, :managed} | {:error, :update_failed | :failed_to_cache}
  def execute, do: manage_sessions()

  #########
  # SERVER
  #########

  # coveralls-ignore-start

  @impl true
  def init(_args) do
    Logger.info("Session manager started")

    state = %{
      started_at: NaiveDateTime.utc_now(),
      updated_at: nil,
      scheduled_to: nil
    }

    {:ok, state, {:continue, :schedule_work}}
  end

  @impl true
  def handle_continue(:schedule_work, state) do
    Logger.info("Session manager scheduling job.")

    state = schedule_work(state)

    {:noreply, state}
  end

  @impl true
  def handle_call(:check, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info(:manage, state) do
    # Updating session statuses and adding active ones to cache
    manage_sessions()

    # Updating state
    state = %{state | updated_at: NaiveDateTime.utc_now()}

    {:noreply, state, {:continue, :schedule_work}}
  end

  # coveralls-ignore-stop

  ##########
  # Helpers
  ##########

  defp manage_sessions do
    Multi.new()
    |> Multi.run(:update_statuses, fn _repo, _changes ->
      update_sessions_status()
    end)
    |> Multi.run(:update_cache, fn _repo, _changes ->
      set_active_sessions_cache()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _response} ->
        Logger.info("Succeeds in managing sessions")
        {:ok, :sessions_updated}

      {:error, step, err, _changes} ->
        Logger.error("Failed to manage sessions in step #{inspect(step)}", reason: err)
        {:error, err}
    end
  end

  defp update_sessions_status do
    now = NaiveDateTime.utc_now()
    create_after = NaiveDateTime.add(now, @query_interval, :second)

    [status: "active", created_after: create_after, expires_before: now]
    |> Session.query()
    |> Repo.update_all(set: [status: "expired"])
    |> case do
      {count, _} when is_integer(count) ->
        Logger.debug("Session manager expired #{inspect(count)} sessions")
        {:ok, count}

      error ->
        Logger.error("Session manager failed to expire sessions", error: inspect(error))
        {:error, :update_failed}
    end
  end

  defp set_active_sessions_cache do
    today = Date.utc_today()
    {:ok, create_after} = NaiveDateTime.new(today, ~T[00:00:00])

    # Getting all active sessions today
    sessions_to_cache =
      [status: "active", created_after: create_after]
      |> Session.query()
      |> Repo.all()
      |> Enum.map(&build_cache/1)

    # Cleanup the cache
    Cache.flush()

    # Set up active sessions on cache
    sessions_to_cache
    |> Cache.set_many()
    |> case do
      :ok ->
        Logger.debug("Session manager cached sessions with success")
        {:ok, :cache_updated}

      {:error, keys} ->
        Logger.error("Session manager failed to cache sessions", keys: inspect(keys))
        {:error, :failed_to_cache}
    end
  end

  defp build_cache(%Session{jti: jti, claims: %{"exp" => exp}} = session) do
    %Nebulex.Object{
      key: jti,
      value: session,
      version: 1,
      expire_at: exp
    }
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
