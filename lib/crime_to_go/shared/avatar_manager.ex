defmodule CrimeToGo.Shared.AvatarManager do
  @moduledoc """
  Handles avatar selection and management for players.
  
  This module provides functions for:
  - Getting available avatars
  - Checking which avatars are taken
  - Generating random available avatars
  - Optimized avatar selection for performance
  """

  @doc """
  Gets all available avatar filenames.
  """
  def all_avatars do
    [
      "avatar_01.svg", "avatar_02.svg", "avatar_03.svg", "avatar_04.svg",
      "avatar_05.svg", "avatar_06.svg", "avatar_07.svg", "avatar_08.svg",
      "avatar_09.svg", "avatar_10.svg", "avatar_11.svg", "avatar_12.svg",
      "avatar_13.svg", "avatar_14.svg", "avatar_15.svg", "avatar_16.svg",
      "avatar_17.svg", "avatar_18.svg", "avatar_19.svg", "avatar_20.svg",
      "avatar_21.svg", "avatar_22.svg", "avatar_23.svg", "avatar_24.svg"
    ]
  end

  @doc """
  Gets the set of avatars that are already taken by existing players.
  
  ## Examples
  
      taken = AvatarManager.get_taken_avatars(players)
      #=> #MapSet<["avatar_01.svg", "avatar_05.svg"]>
  """
  def get_taken_avatars(players) do
    players
    |> Enum.map(& &1.avatar_file_name)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  @doc """
  Gets available avatars (not taken by existing players).
  
  ## Examples
  
      available = AvatarManager.get_available_avatars(players)
      #=> ["avatar_02.svg", "avatar_03.svg", ...]
  """
  def get_available_avatars(players) do
    taken_avatars = get_taken_avatars(players)
    
    all_avatars()
    |> Enum.reject(&MapSet.member?(taken_avatars, &1))
  end

  @doc """
  Gets a random selection of available avatars, excluding the current player's avatar.
  
  Optimized version that handles edge cases:
  - If there are fewer available avatars than requested, returns all available
  - Excludes the current player's avatar from the selection
  - Ensures randomization for better UX
  
  ## Examples
  
      avatars = AvatarManager.get_random_available_avatars(players, 6, "avatar_01.svg")
      #=> ["avatar_03.svg", "avatar_07.svg", "avatar_12.svg", ...]
  """
  def get_random_available_avatars(players, count, current_avatar \\ nil) do
    taken_avatars = get_taken_avatars(players)
    
    get_random_available_avatars_optimized(taken_avatars, count, current_avatar)
  end

  @doc """
  Optimized version of random avatar selection.
  
  This version takes a precomputed set of taken avatars for better performance
  when called multiple times with the same player list.
  """
  def get_random_available_avatars_optimized(taken_avatars, count, current_avatar \\ nil) do
    available_avatars = 
      all_avatars()
      |> Enum.reject(&MapSet.member?(taken_avatars, &1))
      |> Enum.reject(&(&1 == current_avatar))

    # If we have fewer available avatars than requested, return all available
    actual_count = min(count, length(available_avatars))
    
    available_avatars
    |> Enum.shuffle()
    |> Enum.take(actual_count)
  end

  @doc """
  Checks if an avatar is available (not taken by existing players).
  
  ## Examples
  
      AvatarManager.avatar_available?(players, "avatar_01.svg")
      #=> false
      
      AvatarManager.avatar_available?(players, "avatar_99.svg")
      #=> true
  """
  def avatar_available?(players, avatar_filename) do
    taken_avatars = get_taken_avatars(players)
    not MapSet.member?(taken_avatars, avatar_filename)
  end

  @doc """
  Gets the first available avatar from the full list.
  
  Useful as a fallback when no specific avatar is requested.
  
  ## Examples
  
      AvatarManager.get_first_available_avatar(players)
      #=> "avatar_03.svg"
  """
  def get_first_available_avatar(players) do
    taken_avatars = get_taken_avatars(players)
    
    all_avatars()
    |> Enum.find(&(not MapSet.member?(taken_avatars, &1)))
  end

  @doc """
  Gets avatar statistics for debugging/admin purposes.
  
  ## Examples
  
      AvatarManager.get_avatar_stats(players)
      #=> %{total: 24, taken: 3, available: 21}
  """
  def get_avatar_stats(players) do
    taken_count = 
      players
      |> Enum.count(&(&1.avatar_file_name != nil))
    
    total_count = length(all_avatars())
    
    %{
      total: total_count,
      taken: taken_count,
      available: total_count - taken_count
    }
  end
end