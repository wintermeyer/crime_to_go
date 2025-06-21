defmodule CrimeToGo.Game.CountdownServer do
  @moduledoc """
  GenServer that manages game countdown timers.
  
  Each active game has a countdown timer that starts at 30 minutes
  and counts down to zero. The timer ticks every minute, and in the
  last 60 seconds, it ticks every second for dramatic effect.
  """
  use GenServer
  require Logger

  alias CrimeToGo.Game
  alias CrimeToGo.Shared

  # Game duration in seconds (30 minutes)
  @game_duration_seconds 30 * 60

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a countdown timer for a game.
  """
  def start_countdown(%Game.Game{} = game) do
    GenServer.cast(__MODULE__, {:start_countdown, game})
  end

  @doc """
  Stops a countdown timer for a game.
  """
  def stop_countdown(game_id) do
    GenServer.cast(__MODULE__, {:stop_countdown, game_id})
  end

  @doc """
  Gets the remaining time for a game.
  Returns {:ok, seconds_remaining} or {:error, :not_found}
  """
  def get_remaining_time(game_id) do
    GenServer.call(__MODULE__, {:get_remaining_time, game_id})
  end

  @doc """
  Recovers countdowns for all active games on startup.
  """
  def recover_countdowns do
    GenServer.cast(__MODULE__, :recover_countdowns)
  end

  ## Callbacks

  def init(_opts) do
    # Schedule recovery check after initialization
    Process.send_after(self(), :recover_on_startup, 1000)
    {:ok, %{timers: %{}}}
  end

  def handle_cast({:start_countdown, game}, state) do
    # Cancel any existing timer for this game
    state = cancel_timer(state, game.id)
    
    # Calculate remaining seconds
    remaining_seconds = calculate_remaining_seconds(game)
    
    if remaining_seconds > 0 do
      # Schedule the next tick
      timer_ref = schedule_next_tick(game.id, remaining_seconds)
      
      # Broadcast initial countdown
      broadcast_countdown(game.id, remaining_seconds)
      
      # Store timer info
      timer_info = %{
        game_id: game.id,
        start_at: game.start_at,
        timer_ref: timer_ref,
        remaining_seconds: remaining_seconds
      }
      
      new_state = put_in(state, [:timers, game.id], timer_info)
      {:noreply, new_state}
    else
      # Game already ended
      Game.end_game(game)
      {:noreply, state}
    end
  end

  def handle_cast({:stop_countdown, game_id}, state) do
    new_state = cancel_timer(state, game_id)
    {:noreply, new_state}
  end

  def handle_cast(:recover_countdowns, state) do
    # Find all active games and restart their countdowns
    games = Game.list_games()
    active_games = Enum.filter(games, &(&1.state == "active" && &1.start_at != nil))
    
    new_state = Enum.reduce(active_games, state, fn game, acc_state ->
      remaining_seconds = calculate_remaining_seconds(game)
      
      if remaining_seconds > 0 do
        timer_ref = schedule_next_tick(game.id, remaining_seconds)
        broadcast_countdown(game.id, remaining_seconds)
        
        timer_info = %{
          game_id: game.id,
          start_at: game.start_at,
          timer_ref: timer_ref,
          remaining_seconds: remaining_seconds
        }
        
        put_in(acc_state, [:timers, game.id], timer_info)
      else
        # Game time expired while system was down
        Game.end_game(game)
        acc_state
      end
    end)
    
    Logger.info("Recovered #{map_size(new_state.timers)} game countdowns")
    {:noreply, new_state}
  end

  def handle_call({:get_remaining_time, game_id}, _from, state) do
    case get_in(state, [:timers, game_id]) do
      nil ->
        {:reply, {:error, :not_found}, state}
      
      timer_info ->
        game = %{start_at: timer_info.start_at}
        remaining = calculate_remaining_seconds(game)
        {:reply, {:ok, remaining}, state}
    end
  end

  def handle_info({:tick, game_id}, state) do
    case get_in(state, [:timers, game_id]) do
      nil ->
        # Timer was cancelled
        {:noreply, state}
      
      timer_info ->
        game = Game.get_game!(game_id)
        remaining_seconds = calculate_remaining_seconds(game)
        
        if remaining_seconds > 0 do
          # Schedule next tick and broadcast
          timer_ref = schedule_next_tick(game_id, remaining_seconds)
          broadcast_countdown(game_id, remaining_seconds)
          
          # Update timer info
          updated_timer_info = %{timer_info | 
            timer_ref: timer_ref,
            remaining_seconds: remaining_seconds
          }
          
          new_state = put_in(state, [:timers, game_id], updated_timer_info)
          {:noreply, new_state}
        else
          # Time's up! End the game
          Game.end_game(game)
          new_state = cancel_timer(state, game_id)
          broadcast_countdown(game_id, 0)
          {:noreply, new_state}
        end
    end
  end

  def handle_info(:recover_on_startup, state) do
    # Recover countdowns on startup
    handle_cast(:recover_countdowns, state)
  end

  ## Private functions

  defp calculate_remaining_seconds(%{start_at: nil}), do: @game_duration_seconds
  
  defp calculate_remaining_seconds(%{start_at: start_at}) do
    elapsed = DateTime.diff(DateTime.utc_now(), start_at, :second)
    max(0, @game_duration_seconds - elapsed)
  end

  defp schedule_next_tick(game_id, remaining_seconds) do
    # In the last 60 seconds, tick every second
    # Otherwise, tick every minute
    delay = if remaining_seconds <= 60, do: 1_000, else: 60_000
    Process.send_after(self(), {:tick, game_id}, delay)
  end

  defp broadcast_countdown(game_id, remaining_seconds) do
    Shared.broadcast_event("game:#{game_id}", {:countdown_update, remaining_seconds})
  end

  defp cancel_timer(state, game_id) do
    case get_in(state, [:timers, game_id]) do
      nil ->
        state
      
      %{timer_ref: timer_ref} ->
        Process.cancel_timer(timer_ref)
        update_in(state, [:timers], &Map.delete(&1, game_id))
    end
  end
end