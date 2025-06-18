defmodule CrimeToGo.ChatTest do
  use CrimeToGo.DataCase

  alias CrimeToGo.Chat
  alias CrimeToGo.Chat.{ChatRoom, ChatMessage, ChatRoomMember}
  alias CrimeToGo.Game
  alias CrimeToGo.Player

  describe "chat_rooms" do
    setup do
      {:ok, game} = Game.create_game(%{invitation_code: "test123"})

      {:ok, player} =
        Player.create_player(%{
          nickname: "Test Player",
          avatar_file_name: "test.png",
          game_id: game.id
        })

      %{game: game, player: player}
    end

    test "list_chat_rooms_for_game/1 returns chat rooms for specific game", %{game: game} do
      {:ok, game2} = Game.create_game(%{invitation_code: "test456"})

      {:ok, room1} =
        Chat.create_chat_room(%{name: "Room 1", room_type: "public", game_id: game.id})

      {:ok, _room2} =
        Chat.create_chat_room(%{name: "Room 2", room_type: "public", game_id: game2.id})

      assert Chat.list_chat_rooms_for_game(game.id) == [room1]
    end

    test "get_chat_room!/1 returns the chat room with given id", %{game: game} do
      {:ok, room} =
        Chat.create_chat_room(%{name: "Test Room", room_type: "public", game_id: game.id})

      assert Chat.get_chat_room!(room.id) == room
    end

    test "create_chat_room/1 with valid data creates a chat room", %{game: game, player: player} do
      attrs = %{name: "Test Room", room_type: "public", game_id: game.id, created_by: player.id}
      assert {:ok, %ChatRoom{} = room} = Chat.create_chat_room(attrs)
      assert room.name == "Test Room"
      assert room.room_type == "public"
    end

    test "create_chat_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_chat_room(%{})
    end

    test "create_public_chat_room/1 creates a public chat room", %{game: game} do
      assert {:ok, %ChatRoom{} = room} = Chat.create_public_chat_room(game)
      assert room.name == "General Chat"
      assert room.room_type == "public"
      assert room.game_id == game.id
    end

    test "create_private_chat_room/3 creates a private chat room and adds creator as member", %{
      game: game,
      player: player
    } do
      assert {:ok, %ChatRoom{} = room} =
               Chat.create_private_chat_room(game, player, "Strategy Room")

      assert room.name == "Strategy Room"
      assert room.room_type == "private"
      assert room.game_id == game.id
      assert room.created_by == player.id

      # Check that creator is automatically added as member
      assert Chat.member_of_chat_room?(room.id, player.id)
    end

    test "update_chat_room/2 with valid data updates the chat room", %{game: game} do
      {:ok, room} =
        Chat.create_chat_room(%{name: "Test Room", room_type: "public", game_id: game.id})

      update_attrs = %{name: "Updated Room"}

      assert {:ok, %ChatRoom{} = room} = Chat.update_chat_room(room, update_attrs)
      assert room.name == "Updated Room"
    end

    test "delete_chat_room/1 deletes the chat room", %{game: game} do
      {:ok, room} =
        Chat.create_chat_room(%{name: "Test Room", room_type: "public", game_id: game.id})

      assert {:ok, %ChatRoom{}} = Chat.delete_chat_room(room)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_room!(room.id) end
    end

    test "get_public_chat_room/1 returns public chat room for game", %{game: game} do
      {:ok, public_room} = Chat.create_public_chat_room(game)

      {:ok, _private_room} =
        Chat.create_chat_room(%{name: "Private Room", room_type: "private", game_id: game.id})

      assert Chat.get_public_chat_room(game.id) == public_room
    end

    test "chat_room_name_available?/2 checks name availability within game", %{game: game} do
      assert Chat.chat_room_name_available?(game.id, "Available Room") == true

      {:ok, _room} =
        Chat.create_chat_room(%{name: "Taken Room", room_type: "public", game_id: game.id})

      assert Chat.chat_room_name_available?(game.id, "Taken Room") == false
    end

    test "validates room_type", %{game: game} do
      valid_attrs = %{name: "Test Room", room_type: "invalid", game_id: game.id}
      assert {:error, changeset} = Chat.create_chat_room(valid_attrs)
      assert %{room_type: ["is invalid"]} = errors_on(changeset)
    end

    test "enforces unique name per game", %{game: game} do
      attrs = %{name: "Duplicate Room", room_type: "public", game_id: game.id}
      assert {:ok, _room1} = Chat.create_chat_room(attrs)
      assert {:error, changeset} = Chat.create_chat_room(attrs)
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "chat_messages" do
    setup do
      {:ok, game} = Game.create_game(%{invitation_code: "test123"})

      {:ok, player} =
        Player.create_player(%{
          nickname: "Test Player",
          avatar_file_name: "test.png",
          game_id: game.id
        })

      {:ok, room} =
        Chat.create_chat_room(%{name: "Test Room", room_type: "public", game_id: game.id})

      %{game: game, player: player, room: room}
    end

    test "list_chat_messages_for_room/1 returns messages for room excluding deleted", %{
      room: room,
      player: player
    } do
      {:ok, _message1} =
        Chat.create_chat_message(%{content: "Hello", chat_room_id: room.id, player_id: player.id})

      {:ok, message2} =
        Chat.create_chat_message(%{content: "World", chat_room_id: room.id, player_id: player.id})

      # Soft delete one message
      {:ok, _deleted} = Chat.delete_chat_message(message2)

      messages = Chat.list_chat_messages_for_room(room.id)
      assert length(messages) == 1
      assert List.first(messages).content == "Hello"
    end

    test "get_chat_message!/1 returns the chat message with given id", %{
      room: room,
      player: player
    } do
      {:ok, message} =
        Chat.create_chat_message(%{
          content: "Test message",
          chat_room_id: room.id,
          player_id: player.id
        })

      assert Chat.get_chat_message!(message.id) == message
    end

    test "create_chat_message/1 with valid data creates a chat message", %{
      room: room,
      player: player
    } do
      attrs = %{content: "Test message", chat_room_id: room.id, player_id: player.id}
      assert {:ok, %ChatMessage{} = message} = Chat.create_chat_message(attrs)
      assert message.content == "Test message"
      assert message.deleted_at == nil
    end

    test "create_chat_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_chat_message(%{})
    end

    test "delete_chat_message/1 soft deletes the message", %{room: room, player: player} do
      {:ok, message} =
        Chat.create_chat_message(%{
          content: "Test message",
          chat_room_id: room.id,
          player_id: player.id
        })

      assert {:ok, %ChatMessage{} = deleted_message} = Chat.delete_chat_message(message)
      assert deleted_message.deleted_at != nil
      assert ChatMessage.deleted?(deleted_message) == true
    end

    test "validates content length", %{room: room, player: player} do
      long_content = String.duplicate("a", 1001)
      attrs = %{content: long_content, chat_room_id: room.id, player_id: player.id}

      assert {:error, changeset} = Chat.create_chat_message(attrs)
      assert %{content: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "ChatMessage.deleted?/1 checks if message is deleted", %{room: room, player: player} do
      {:ok, message} =
        Chat.create_chat_message(%{
          content: "Test message",
          chat_room_id: room.id,
          player_id: player.id
        })

      assert ChatMessage.deleted?(message) == false

      {:ok, deleted_message} = Chat.delete_chat_message(message)
      assert ChatMessage.deleted?(deleted_message) == true
    end
  end

  describe "chat_room_members" do
    setup do
      {:ok, game} = Game.create_game(%{invitation_code: "test123"})

      {:ok, player1} =
        Player.create_player(%{
          nickname: "Player 1",
          avatar_file_name: "player1.png",
          game_id: game.id
        })

      {:ok, player2} =
        Player.create_player(%{
          nickname: "Player 2",
          avatar_file_name: "player2.png",
          game_id: game.id
        })

      {:ok, room} =
        Chat.create_chat_room(%{name: "Test Room", room_type: "private", game_id: game.id})

      %{game: game, player1: player1, player2: player2, room: room}
    end

    test "list_chat_room_members/1 returns members for room", %{
      room: room,
      player1: player1,
      player2: player2
    } do
      {:ok, _member1} = Chat.add_member_to_chat_room(room, player1)
      {:ok, _member2} = Chat.add_member_to_chat_room(room, player2)

      members = Chat.list_chat_room_members(room.id)
      assert length(members) == 2
    end

    test "get_chat_room_member/2 returns member for room and player", %{
      room: room,
      player1: player1
    } do
      {:ok, member} = Chat.add_member_to_chat_room(room, player1)
      assert Chat.get_chat_room_member(room.id, player1.id) == member
    end

    test "get_chat_room_member/2 returns nil for non-member", %{room: room, player1: player1} do
      assert Chat.get_chat_room_member(room.id, player1.id) == nil
    end

    test "add_member_to_chat_room/2 adds player to room", %{room: room, player1: player1} do
      assert {:ok, %ChatRoomMember{} = member} = Chat.add_member_to_chat_room(room, player1)
      assert member.chat_room_id == room.id
      assert member.player_id == player1.id
      assert member.joined_at != nil
    end

    test "add_member_to_chat_room/2 prevents duplicate membership", %{
      room: room,
      player1: player1
    } do
      {:ok, _member1} = Chat.add_member_to_chat_room(room, player1)
      assert {:error, changeset} = Chat.add_member_to_chat_room(room, player1)
      assert %{player_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "remove_member_from_chat_room/2 removes player from room", %{
      room: room,
      player1: player1
    } do
      {:ok, _member} = Chat.add_member_to_chat_room(room, player1)
      assert {:ok, %ChatRoomMember{}} = Chat.remove_member_from_chat_room(room, player1)
      assert Chat.get_chat_room_member(room.id, player1.id) == nil
    end

    test "remove_member_from_chat_room/2 returns error for non-member", %{
      room: room,
      player1: player1
    } do
      assert {:error, :not_found} = Chat.remove_member_from_chat_room(room, player1)
    end

    test "member_of_chat_room?/2 checks membership", %{
      room: room,
      player1: player1,
      player2: player2
    } do
      assert Chat.member_of_chat_room?(room.id, player1.id) == false

      {:ok, _member} = Chat.add_member_to_chat_room(room, player1)
      assert Chat.member_of_chat_room?(room.id, player1.id) == true
      assert Chat.member_of_chat_room?(room.id, player2.id) == false
    end

    test "list_private_chat_rooms_for_player/2 returns private rooms player is member of", %{
      game: game,
      player1: player1,
      player2: player2
    } do
      {:ok, _room1} = Chat.create_private_chat_room(game, player1, "Player 1 Room")
      {:ok, room2} = Chat.create_private_chat_room(game, player2, "Player 2 Room")
      {:ok, _member} = Chat.add_member_to_chat_room(room2, player1)

      rooms = Chat.list_private_chat_rooms_for_player(game.id, player1.id)
      room_names = Enum.map(rooms, & &1.name) |> Enum.sort()
      assert room_names == ["Player 1 Room", "Player 2 Room"]
    end
  end
end
