defmodule ResourceManager.Credentials.Manager do
  @moduledoc """
  GenServer for dealing with session expirations.
  """

  use GenServer

  require Logger

  alias ResourceManager.Credentials.Cache

  @typedoc "Credentials manager supervisor state"
  @type state :: %{
          started_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t() | nil,
          scheduled_to: NaiveDateTime.t() | nil
        }

  # One hour interval
  @schedule_interval 60 * 60

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
  def execute, do: manage_passwords()

  #########
  # SERVER
  #########

  # coveralls-ignore-start

  @impl true
  def init(_args) do
    Logger.info("Credential manager started")

    state = %{
      started_at: NaiveDateTime.utc_now(),
      updated_at: nil,
      scheduled_to: nil
    }

    {:ok, state, {:continue, :manage}}
  end

  @impl true
  def handle_continue(:manage, state) do
    # Updating session statuses and adding active ones to cache
    manage_passwords()

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

  defp manage_passwords do
    if Cache.size() == 0 do
      Logger.debug("Credential manager Loading cache from dump")

      file_path()
      |> File.read!()
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(fn pwd -> %Nebulex.Object{key: pwd, value: pwd, version: 1} end)
      |> Cache.set_many()
      |> case do
        :ok ->
          Logger.debug("Credential manager cache loaded with success")
          {:ok, :managed}

        {:error, _error} ->
          Logger.error("Credential manager failed to load cache from file")
          {:error, :load_failed}
      end
    else
      Logger.debug("Credential manager cache already loaded")
      {:ok, :managed}
    end
  end

  defp file_path do
    :resource_manager
    |> :code.priv_dir()
    |> Path.join("/passwords/common_passwords.txt")
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
