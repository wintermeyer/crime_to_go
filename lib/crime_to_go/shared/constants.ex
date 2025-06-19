defmodule CrimeToGo.Shared.Constants do
  @moduledoc """
  Application-wide constants and configuration values.

  This module centralizes commonly used constants across the application,
  making them easier to maintain and update.
  """

  @doc """
  Valid game states.
  """
  def game_states, do: ~w(pre_game active post_game)

  @doc """
  Valid chat room types.
  """
  def chat_room_types, do: ~w(public private)

  @doc """
  Supported languages for the application.
  """
  def supported_languages, do: ~w(de en fr es it tr ru uk)

  @doc """
  Default language for the application.
  """
  def default_language, do: "en"

  @doc """
  Maximum length constraints for various fields.
  """
  def max_lengths do
    %{
      nickname: 140,
      avatar_file_name: 255,
      chat_room_name: 100,
      chat_message: 1000,
      invitation_code: 20,
      game_code: 20
    }
  end

  @doc """
  Valid digits for game code generation (excludes 0, 1, and 7 for clarity).
  """
  def game_code_digits, do: ~w(2 3 4 5 6 8 9)

  @doc """
  Number of digits in a game code.
  """
  def game_code_length, do: 12

  @doc """
  Number of avatar images available.
  """
  def avatar_count, do: 50

  @doc """
  Avatar filename pattern.
  """
  def avatar_pattern, do: "adventurer_avatar_%02d.webp"

  @doc """
  Gets the maximum length for a specific field.

  ## Examples

      iex> max_length(:nickname)
      140
  """
  @spec max_length(atom()) :: integer()
  def max_length(field) when is_atom(field) do
    Map.get(max_lengths(), field, 255)
  end

  @doc """
  Generates the list of available avatar filenames.

  ## Examples

      iex> available_avatars()
      ["adventurer_avatar_01.webp", "adventurer_avatar_02.webp", ...]
  """
  @spec available_avatars() :: [String.t()]
  def available_avatars do
    1..avatar_count()
    |> Enum.map(&String.pad_leading(to_string(&1), 2, "0"))
    |> Enum.map(&"adventurer_avatar_#{&1}.webp")
  end
end
