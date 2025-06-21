defmodule CrimeToGo.Game.CountdownServer do
  @moduledoc """
  GenServer that manages game countdown timers.
  
  Each active game has a 30-minute countdown timer.
  Timer ticks every minute, and every second in the last 60 seconds.
  """
  use GenServer
  require Logger

  # Game duration: 30 minutes (in seconds)
  @game_duration_seconds 30 * 60

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a countdown for a game.
  """
  def start_countdown(game_id, start_at \\ nil) do
    GenServer.cast(__MODULE__, {:start_countdown, game_id, start_at})
  end

  @doc """
  Stops a countdown for a game.
  """
  def stop_countdown(game_id) do
    GenServer.cast(__MODULE__, {:stop_countdown, game_id})
  end

  @doc """
  Gets the remaining seconds for a game.
  Returns {:ok, seconds} or {:error, :not_found}
  """
  def get_remaining_time(game_id) do
    GenServer.call(__MODULE__, {:get_remaining_time, game_id})
  end

  ## Callbacks

  def init(_opts) do
    # State will hold timers: %{game_id => {timer_ref, start_at}}
    # Schedule recovery after init
    Process.send_after(self(), :recover_countdowns, 1000)
    {:ok, %{}}
  end

  def handle_cast({:start_countdown, game_id, start_at}, state) do
    # Cancel existing timer if any
    state = cancel_timer(state, game_id)
    
    # Use provided start_at or current time
    start_at = start_at || DateTime.utc_now()
    
    # Calculate remaining seconds
    remaining = calculate_remaining_seconds(start_at)
    
    if remaining > 0 do
      # Schedule next tick
      timer_ref = schedule_tick(game_id, remaining)
      
      # Broadcast initial countdown
      broadcast_countdown(game_id, remaining)
      
      # Store timer info
      new_state = Map.put(state, game_id, {timer_ref, start_at})
      {:noreply, new_state}
    else
      # Game already expired
      {:noreply, state}
    end
  end

  def handle_cast({:stop_countdown, game_id}, state) do
    new_state = cancel_timer(state, game_id)
    {:noreply, new_state}
  end

  def handle_call({:get_remaining_time, game_id}, _from, state) do
    case Map.get(state, game_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      
      {_timer_ref, start_at} ->
        remaining = calculate_remaining_seconds(start_at)
        {:reply, {:ok, remaining}, state}
    end
  end

  def handle_info(:recover_countdowns, state) do
    # Recover countdowns for active games on startup
    Logger.info("CountdownServer: Recovering active game countdowns...")
    
    # Get all active games
    games = CrimeToGo.Game.list_games()
    active_games = Enum.filter(games, &(&1.state == "active" && &1.start_at != nil))
    
    # Start countdown for each active game
    new_state = Enum.reduce(active_games, state, fn game, acc_state ->
      remaining = calculate_remaining_seconds(game.start_at)
      
      if remaining > 0 do
        timer_ref = schedule_tick(game.id, remaining)
        broadcast_countdown(game.id, remaining)
        Map.put(acc_state, game.id, {timer_ref, game.start_at})
      else
        # Game expired while system was down
        Task.start(fn -> CrimeToGo.Game.end_game(game) end)
        acc_state
      end
    end)
    
    Logger.info("CountdownServer: Recovered #{map_size(new_state)} active countdowns")
    {:noreply, new_state}
  end

  def handle_info({:tick, game_id}, state) do
    case Map.get(state, game_id) do
      nil ->
        # Timer was cancelled
        {:noreply, state}
      
      {_timer_ref, start_at} ->
        remaining = calculate_remaining_seconds(start_at)
        
        if remaining > 0 do
          # Schedule next tick
          timer_ref = schedule_tick(game_id, remaining)
          
          # Broadcast update
          broadcast_countdown(game_id, remaining)
          
          # Update state
          new_state = Map.put(state, game_id, {timer_ref, start_at})
          {:noreply, new_state}
        else
          # Time's up!
          broadcast_countdown(game_id, 0)
          
          # End the game
          Task.start(fn ->
            case CrimeToGo.Game.get_game!(game_id) do
              nil -> :ok
              game -> CrimeToGo.Game.end_game(game)
            end
          end)
          
          # Remove timer from state
          new_state = Map.delete(state, game_id)
          {:noreply, new_state}
        end
    end
  end

  ## Private functions

  defp calculate_remaining_seconds(start_at) do
    elapsed = DateTime.diff(DateTime.utc_now(), start_at, :second)
    max(0, @game_duration_seconds - elapsed)
  end

  defp schedule_tick(game_id, remaining_seconds) do
    # Tick every second in last 60 seconds, otherwise every minute
    delay = if remaining_seconds <= 60, do: 1_000, else: 60_000
    Process.send_after(self(), {:tick, game_id}, delay)
  end

  defp broadcast_countdown(game_id, remaining_seconds) do
    Phoenix.PubSub.broadcast(
      CrimeToGo.PubSub,
      "game:#{game_id}",
      {:countdown_update, remaining_seconds}
    )
  end

  defp cancel_timer(state, game_id) do
    case Map.get(state, game_id) do
      nil -> 
        state
      
      {timer_ref, _start_at} ->
        Process.cancel_timer(timer_ref)
        Map.delete(state, game_id)
    end
  end
end