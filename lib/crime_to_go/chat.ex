defmodule CrimeToGo.Chat do
  @moduledoc """
  The Chat context.

  This context manages chat-related operations including chat rooms, messages,
  and room membership. It handles both public and private chat functionality.
  """

  import Ecto.Query, warn: false
  alias CrimeToGo.Repo

  alias CrimeToGo.Chat.{ChatRoom, ChatMessage, ChatRoomMember}
  alias CrimeToGo.Game.Game
  alias CrimeToGo.Player.Player

  # Chat Rooms

  @doc """
  Returns the list of chat rooms for a game.

  ## Examples

      iex> list_chat_rooms_for_game("game-id")
      [%ChatRoom{}, ...]

  """
  def list_chat_rooms_for_game(game_id) do
    ChatRoom
    |> where([cr], cr.game_id == ^game_id)
    |> order_by([cr], cr.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single chat room.

  Raises `Ecto.NoResultsError` if the Chat room does not exist.

  ## Examples

      iex> get_chat_room!(123)
      %ChatRoom{}

      iex> get_chat_room!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_chat_room!(id), do: Repo.get!(ChatRoom, id)

  @doc """
  Creates a chat room.

  ## Examples

      iex> create_chat_room(%{field: value})
      {:ok, %ChatRoom{}}

      iex> create_chat_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_room(attrs \\ %{}) do
    %ChatRoom{}
    |> ChatRoom.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a public chat room for a game.

  ## Examples

      iex> create_public_chat_room(game)
      {:ok, %ChatRoom{}}

  """
  def create_public_chat_room(%Game{} = game) do
    create_chat_room(%{
      name: "General Chat",
      room_type: "public",
      game_id: game.id
    })
  end

  @doc """
  Creates a private chat room.

  ## Examples

      iex> create_private_chat_room(game, player, "Strategy Room")
      {:ok, %ChatRoom{}}

  """
  def create_private_chat_room(%Game{} = game, %Player{} = creator, name) do
    case create_chat_room(%{
           name: name,
           room_type: "private",
           game_id: game.id,
           created_by: creator.id
         }) do
      {:ok, chat_room} ->
        # Automatically add the creator as a member
        {:ok, _} = add_member_to_chat_room(chat_room, creator)
        {:ok, chat_room}

      error ->
        error
    end
  end

  @doc """
  Updates a chat room.

  ## Examples

      iex> update_chat_room(chat_room, %{field: new_value})
      {:ok, %ChatRoom{}}

      iex> update_chat_room(chat_room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_room(%ChatRoom{} = chat_room, attrs) do
    chat_room
    |> ChatRoom.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat room.

  ## Examples

      iex> delete_chat_room(chat_room)
      {:ok, %ChatRoom{}}

      iex> delete_chat_room(chat_room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_room(%ChatRoom{} = chat_room) do
    Repo.delete(chat_room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat room changes.

  ## Examples

      iex> change_chat_room(chat_room)
      %Ecto.Changeset{data: %ChatRoom{}}

  """
  def change_chat_room(%ChatRoom{} = chat_room, attrs \\ %{}) do
    ChatRoom.changeset(chat_room, attrs)
  end

  # Chat Messages

  @doc """
  Returns the list of chat messages for a chat room (excluding deleted messages).

  ## Examples

      iex> list_chat_messages_for_room("room-id")
      [%ChatMessage{}, ...]

  """
  def list_chat_messages_for_room(chat_room_id) do
    ChatMessage
    |> where([cm], cm.chat_room_id == ^chat_room_id and is_nil(cm.deleted_at))
    |> order_by([cm], cm.inserted_at)
    |> preload(:player)
    |> Repo.all()
  end

  @doc """
  Gets a single chat message.

  Raises `Ecto.NoResultsError` if the Chat message does not exist.

  ## Examples

      iex> get_chat_message!(123)
      %ChatMessage{}

      iex> get_chat_message!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_chat_message!(id), do: Repo.get!(ChatMessage, id)

  @doc """
  Creates a chat message.

  ## Examples

      iex> create_chat_message(%{field: value})
      {:ok, %ChatMessage{}}

      iex> create_chat_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_message(attrs \\ %{}) do
    %ChatMessage{}
    |> ChatMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Soft deletes a chat message.

  ## Examples

      iex> delete_chat_message(chat_message)
      {:ok, %ChatMessage{}}

  """
  def delete_chat_message(%ChatMessage{} = chat_message) do
    chat_message
    |> ChatMessage.soft_delete()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat message changes.

  ## Examples

      iex> change_chat_message(chat_message)
      %Ecto.Changeset{data: %ChatMessage{}}

  """
  def change_chat_message(%ChatMessage{} = chat_message, attrs \\ %{}) do
    ChatMessage.changeset(chat_message, attrs)
  end

  # Chat Room Members

  @doc """
  Returns the list of chat room members for a chat room.

  ## Examples

      iex> list_chat_room_members("room-id")
      [%ChatRoomMember{}, ...]

  """
  def list_chat_room_members(chat_room_id) do
    ChatRoomMember
    |> where([crm], crm.chat_room_id == ^chat_room_id)
    |> preload(:player)
    |> order_by([crm], crm.joined_at)
    |> Repo.all()
  end

  @doc """
  Gets a single chat room member.

  ## Examples

      iex> get_chat_room_member("room-id", "player-id")
      %ChatRoomMember{}

      iex> get_chat_room_member("room-id", "nonexistent")
      nil

  """
  def get_chat_room_member(chat_room_id, player_id) do
    ChatRoomMember
    |> where([crm], crm.chat_room_id == ^chat_room_id and crm.player_id == ^player_id)
    |> Repo.one()
  end

  @doc """
  Adds a member to a chat room.

  ## Examples

      iex> add_member_to_chat_room(chat_room, player)
      {:ok, %ChatRoomMember{}}

      iex> add_member_to_chat_room(chat_room, player)
      {:error, %Ecto.Changeset{}}

  """
  def add_member_to_chat_room(%ChatRoom{} = chat_room, %Player{} = player) do
    %ChatRoomMember{}
    |> ChatRoomMember.changeset(%{
      chat_room_id: chat_room.id,
      player_id: player.id
    })
    |> Repo.insert()
  end

  @doc """
  Removes a member from a chat room.

  ## Examples

      iex> remove_member_from_chat_room(chat_room, player)
      {:ok, %ChatRoomMember{}}

  """
  def remove_member_from_chat_room(%ChatRoom{} = chat_room, %Player{} = player) do
    case get_chat_room_member(chat_room.id, player.id) do
      nil -> {:error, :not_found}
      member -> Repo.delete(member)
    end
  end

  @doc """
  Checks if a player is a member of a chat room.

  ## Examples

      iex> member_of_chat_room?("room-id", "player-id")
      true

      iex> member_of_chat_room?("room-id", "nonmember-id")
      false

  """
  def member_of_chat_room?(chat_room_id, player_id) do
    not is_nil(get_chat_room_member(chat_room_id, player_id))
  end

  @doc """
  Gets public chat room for a game.

  ## Examples

      iex> get_public_chat_room("game-id")
      %ChatRoom{}

  """
  def get_public_chat_room(game_id) do
    ChatRoom
    |> where([cr], cr.game_id == ^game_id and cr.room_type == "public")
    |> Repo.one()
  end

  @doc """
  Gets private chat rooms for a game that a player is a member of.

  ## Examples

      iex> list_private_chat_rooms_for_player("game-id", "player-id")
      [%ChatRoom{}, ...]

  """
  def list_private_chat_rooms_for_player(game_id, player_id) do
    from(cr in ChatRoom,
      join: crm in ChatRoomMember,
      on: cr.id == crm.chat_room_id,
      where: cr.game_id == ^game_id and cr.room_type == "private" and crm.player_id == ^player_id,
      order_by: cr.inserted_at
    )
    |> Repo.all()
  end

  @doc """
  Checks if a chat room name is available within a game.

  ## Examples

      iex> chat_room_name_available?("game-id", "Strategy Room")
      true

      iex> chat_room_name_available?("game-id", "General Chat")
      false

  """
  def chat_room_name_available?(game_id, name) do
    ChatRoom
    |> where([cr], cr.game_id == ^game_id and cr.name == ^name)
    |> Repo.one()
    |> is_nil()
  end
end
