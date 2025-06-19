defmodule CrimeToGo.Shared.Validations do
  @moduledoc """
  Common validation functions used across different schemas and contexts.

  This module provides reusable validation logic to ensure consistency
  and reduce duplication across the application.
  """

  import Ecto.Changeset

  @doc """
  Validates that a nickname is unique within a game (case-insensitive).

  ## Examples

      changeset
      |> validate_unique_nickname_in_game()
  """
  @spec validate_unique_nickname_in_game(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_unique_nickname_in_game(changeset) do
    game_id = get_field(changeset, :game_id)
    nickname = get_field(changeset, :nickname)
    player_id = get_field(changeset, :id)

    case {game_id, nickname} do
      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {game_id, nickname} ->
        if CrimeToGo.Player.nickname_available_case_insensitive?(game_id, nickname, player_id) do
          changeset
        else
          add_error(changeset, :nickname, "is already taken in this game")
        end
    end
  end

  @doc """
  Validates that an avatar is unique within a game.

  ## Examples

      changeset
      |> validate_unique_avatar_in_game()
  """
  @spec validate_unique_avatar_in_game(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_unique_avatar_in_game(changeset) do
    game_id = get_field(changeset, :game_id)
    avatar_file_name = get_field(changeset, :avatar_file_name)

    case {game_id, avatar_file_name} do
      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {game_id, avatar_file_name} ->
        if CrimeToGo.Player.avatar_available?(game_id, avatar_file_name) do
          changeset
        else
          add_error(changeset, :avatar_file_name, "is already taken in this game")
        end
    end
  end

  @doc """
  Validates that a chat room name is unique within a game.

  ## Examples

      changeset
      |> validate_unique_chat_room_name_in_game()
  """
  @spec validate_unique_chat_room_name_in_game(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_unique_chat_room_name_in_game(changeset) do
    game_id = get_field(changeset, :game_id)
    name = get_field(changeset, :name)

    case {game_id, name} do
      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {game_id, name} ->
        if CrimeToGo.Chat.chat_room_name_available?(game_id, name) do
          changeset
        else
          add_error(changeset, :name, "is already taken in this game")
        end
    end
  end

  @doc """
  Validates that a string field contains only safe characters.

  This helps prevent potential security issues with user input.

  ## Examples

      changeset
      |> validate_safe_text(:nickname)
  """
  @spec validate_safe_text(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_safe_text(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      if String.match?(value, ~r/^[\p{L}\p{N}\p{P}\p{S}\s]+$/u) do
        []
      else
        [{field, "contains invalid characters"}]
      end
    end)
  end

  @doc """
  Validates that a nickname follows the required format:
  - 2-15 characters long
  - Only alphanumeric characters and underscores
  - Cannot start with an underscore

  ## Examples

      changeset
      |> validate_nickname_format(:nickname)
  """
  @spec validate_nickname_format(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_nickname_format(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      cond do
        String.length(value) < 2 ->
          [{field, {"must be at least 2 characters long", [validation: :length, kind: :min, count: 2]}}]

        String.length(value) > 15 ->
          [{field, {"must be at most 15 characters long", [validation: :length, kind: :max, count: 15]}}]

        String.starts_with?(value, "_") ->
          [{field, {"cannot start with an underscore", [validation: :format]}}]

        not String.match?(value, ~r/^[a-zA-Z0-9_]+$/) ->
          [{field, {"can only contain letters, numbers, and underscores", [validation: :format]}}]

        true ->
          []
      end
    end)
  end

  @doc """
  Validates that a field is not empty after trimming whitespace.

  ## Examples

      changeset
      |> validate_not_blank(:nickname)
  """
  @spec validate_not_blank(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_not_blank(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      if String.trim(value) == "" do
        [{field, "cannot be blank"}]
      else
        []
      end
    end)
  end
end
