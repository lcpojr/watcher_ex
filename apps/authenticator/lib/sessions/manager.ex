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

  #########
  # CLIENT
  #########

  @doc "Starts the `GenServer"
  @spec start_link(args :: keyword()) :: {:ok, pid()} | :ignore | {:error, keyword()}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @doc "Checks #{__MODULE__} actual state"
  @spec check(pid() | __MODULE__) :: state()
  def check(pid \\ __MODULE__), do: GenServer.call(pid, :check)

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
    create_after = NaiveDateTime.utc_now() |> NaiveDateTime.add(verification_interval(), :second)

    [expired?: true, create_after: create_after]
    |> Session.query()
    |> Repo.stream(max_rows: 100)
    |> Stream.chunk_every(100)
    |> Stream.map(fn sessions ->
      ids =
        sessions
        |> Enum.reject(&(&1.status != "active"))
        |> Enum.map(& &1.id)

      [ids: ids]
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
    end)
  end

  defp schedule_work(state) do
    interval = schedule_interval()

    Process.send_after(__MODULE__, :query, interval)

    # Updating state
    %{state | scheduled_to: NaiveDateTime.add(NaiveDateTime.utc_now(), interval, :second)}
  end

  defp schedule_interval, do: Keyword.get(config(), :schedule_interval, 60)
  defp verification_interval, do: Keyword.get(config(), :verification_interval, 60 * 5) * -1
  defp config, do: Application.get_env(:authenticator, __MODULE__, [])
end
