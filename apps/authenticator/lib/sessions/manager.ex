defmodule Authenticator.Sessions.Manager do
  @moduledoc """
  GenServer for dealing with session expirations.
  """

  use GenServer

  require Logger

  alias Authenticator.Repo
  alias Authenticator.Sessions.Schemas.Session

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

  @doc "Starts the `GenServer"
  @spec start_link(args :: keyword()) :: {:ok, pid()} | :ignore | {:error, keyword()}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @doc "Checks #{__MODULE__} actual state"
  @spec check(process_id :: pid() | __MODULE__) :: state()
  def check(pid \\ __MODULE__), do: GenServer.call(pid, :check)

  @doc "Executes the status management"
  @spec execute() :: :ok | {:error, :update_failed}
  def execute, do: update_sessions_status()

  #########
  # SERVER
  #########

  @impl true
  def init(_args) do
    Logger.info("Session Manager started")

    state = %{
      started_at: NaiveDateTime.utc_now(),
      updated_at: nil,
      scheduled_to: nil
    }

    {:ok, state, {:continue, :schedule_work}}
  end

  @impl true
  def handle_continue(:schedule_work, state) do
    Logger.info("Session Manager scheduling job.")

    state = schedule_work(state)

    {:noreply, state}
  end

  @impl true
  def handle_call(:check, _from, state), do: {:reply, state, state}

  def handle_call(:execute, _from, state) do
    # Runs update sessions manually
    update_sessions_status()

    {:reply, state, state}
  end

  @impl true
  def handle_info(:query, state) do
    update_sessions_status()

    # Updating state
    state = %{state | updated_at: NaiveDateTime.utc_now()}

    {:noreply, state, {:continue, :schedule_work}}
  end

  ##########
  # Helpers
  ##########

  defp update_sessions_status do
    now = NaiveDateTime.utc_now()
    create_after = NaiveDateTime.add(now, @query_interval, :second)

    [status: "active", created_after: create_after, expires_before: now]
    |> Session.query()
    |> Repo.update_all(set: [status: "expired"])
    |> case do
      {count, _} ->
        Logger.debug("Session Manager expired #{inspect(count)} sessions")
        :ok

      error ->
        Logger.error("Session manager failed to expire sessions", error: inspect(error))
        {:error, :update_failed}
    end
  end

  defp schedule_work(state) do
    interval = schedule_interval()
    date_to_schedule = schedule_to(interval)

    Process.send_after(__MODULE__, :query, interval)

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
end
