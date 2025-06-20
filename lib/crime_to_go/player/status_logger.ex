defmodule CrimeToGo.Player.StatusLogger do
  @moduledoc """
  GenServer that debounces offline/online status changes to prevent
  logging rapid reconnections that occur within a short time frame.
  
  When a player goes offline, we schedule a delayed log entry.
  If they come back online within the debounce period (1 second),
  we cancel the offline log to avoid noise in the logs.
  """
  
  use GenServer
  require Logger

  # Debounce period in milliseconds (default 1 second, configurable)
  @debounce_ms Application.compile_env(:crime_to_go, :offline_debounce_ms, 1000)

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Check if the StatusLogger GenServer is running.
  """
  def alive? do
    case GenServer.whereis(__MODULE__) do
      nil -> false
      pid when is_pid(pid) -> Process.alive?(pid)
    end
  end

  @doc """
  Schedule a delayed offline log for a player.
  If the player comes back online within 1 second, this will be cancelled.
  """
  def schedule_offline_log(%CrimeToGo.Player.Player{} = player) do
    try do
      GenServer.cast(__MODULE__, {:schedule_offline_log, player})
    catch
      :exit, _reason ->
        # GenServer is not available, log immediately as fallback
        require Logger
        Logger.warning("StatusLogger not available, logging offline immediately")
        game = CrimeToGo.Game.get_game!(player.game_id)
        CrimeToGo.Game.log_player_offline(game, player)
    end
  end

  @doc """
  Cancel any pending offline log for a player.
  Called when a player comes back online quickly.
  Returns true if there was a scheduled offline log (indicating a quick reconnect).
  """
  def cancel_offline_log(player_id) do
    try do
      GenServer.call(__MODULE__, {:cancel_offline_log, player_id}, 1000)
    catch
      :exit, _reason ->
        # GenServer is not available, assume no scheduled log
        require Logger
        Logger.warning("StatusLogger not available for cancel check")
        false
    end
  end

  ## Server Callbacks

  @impl true
  def init(_args) do
    # State: %{player_id => timer_ref}
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:schedule_offline_log, player}, state) do
    # Cancel any existing timer for this player
    state = cancel_existing_timer(state, player.id)

    # Schedule new offline log
    timer_ref = Process.send_after(self(), {:log_offline, player}, @debounce_ms)
    
    Logger.debug("Scheduled offline log for player #{player.id} (#{player.nickname}) in #{@debounce_ms}ms")
    
    {:noreply, Map.put(state, player.id, timer_ref)}
  end

  @impl true
  def handle_call({:cancel_offline_log, player_id}, _from, state) do
    Logger.debug("Cancelling offline log for player #{player_id}")
    
    was_scheduled = Map.has_key?(state, player_id)
    state = cancel_existing_timer(state, player_id)
    
    {:reply, was_scheduled, state}
  end

  @impl true
  def handle_info({:log_offline, player}, state) do
    # Timer fired - log the offline event
    Logger.debug("Logging offline event for player #{player.id} (#{player.nickname})")
    
    try do
      game = CrimeToGo.Game.get_game!(player.game_id)
      CrimeToGo.Game.log_player_offline(game, player)
    rescue
      error ->
        Logger.error("Failed to log offline event for player #{player.id}: #{inspect(error)}")
    end
    
    # Remove timer from state
    {:noreply, Map.delete(state, player.id)}
  end

  ## Helper Functions

  defp cancel_existing_timer(state, player_id) do
    case Map.get(state, player_id) do
      nil -> 
        state
      timer_ref ->
        Process.cancel_timer(timer_ref)
        Map.delete(state, player_id)
    end
  end
end