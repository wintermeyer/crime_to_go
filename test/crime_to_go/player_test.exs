defmodule CrimeToGo.PlayerTest do
  use CrimeToGo.DataCase

  alias CrimeToGo.Player
  alias CrimeToGo.Player.Player, as: PlayerSchema
  alias CrimeToGo.Game

  describe "players" do
    setup do
      {:ok, game} = Game.create_game(%{invitation_code: "test123"})
      %{game: game}
    end

    @valid_attrs %{nickname: "DetectiveSmith", avatar_file_name: "detective.png"}
    @invalid_attrs %{nickname: nil, avatar_file_name: nil}

    test "list_players/0 returns all players", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert Player.list_players() == [player]
    end

    test "list_players_for_game/1 returns players for specific game", %{game: game} do
      {:ok, game2} = Game.create_game(%{invitation_code: "test456"})

      {:ok, player1} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))

      {:ok, _player2} =
        Player.create_player(
          Map.merge(@valid_attrs, %{game_id: game2.id, nickname: "DetectiveJones"})
        )

      assert Player.list_players_for_game(game.id) == [player1]
    end

    test "get_player!/1 returns the player with given id", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert Player.get_player!(player.id) == player
    end

    test "get_player_by_nickname/2 returns player by nickname within game", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert Player.get_player_by_nickname(game.id, "DetectiveSmith") == player
    end

    test "get_player_by_nickname/2 returns nil for nonexistent nickname", %{game: game} do
      assert Player.get_player_by_nickname(game.id, "Nonexistent") == nil
    end

    test "create_player/1 with valid data creates a player", %{game: game} do
      attrs = Map.put(@valid_attrs, :game_id, game.id)
      assert {:ok, %PlayerSchema{} = player} = Player.create_player(attrs)
      assert player.nickname == "DetectiveSmith"
      assert player.avatar_file_name == "detective.png"
      assert player.game_host == false
      assert player.is_robot == false
    end

    test "create_player/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Player.create_player(@invalid_attrs)
    end

    test "create_player/1 enforces unique nickname per game", %{game: game} do
      attrs = Map.put(@valid_attrs, :game_id, game.id)
      assert {:ok, _player1} = Player.create_player(attrs)
      assert {:error, changeset} = Player.create_player(attrs)
      assert %{nickname: ["is already taken in this game"]} = errors_on(changeset)
    end

    test "create_player/1 enforces unique avatar per game", %{game: game} do
      attrs = Map.put(@valid_attrs, :game_id, game.id)
      assert {:ok, _player1} = Player.create_player(attrs)

      attrs2 = Map.merge(attrs, %{nickname: "DifferentDet"})
      assert {:error, changeset} = Player.create_player(attrs2)
      assert %{avatar_file_name: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_player/2 with valid data updates the player", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      update_attrs = %{nickname: "InspectorSmith"}

      assert {:ok, %PlayerSchema{} = player} = Player.update_player(player, update_attrs)
      assert player.nickname == "InspectorSmith"
    end

    test "update_player/2 with invalid data returns error changeset", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert {:error, %Ecto.Changeset{}} = Player.update_player(player, @invalid_attrs)
      assert player == Player.get_player!(player.id)
    end

    test "delete_player/1 deletes the player", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert {:ok, %PlayerSchema{}} = Player.delete_player(player)
      assert_raise Ecto.NoResultsError, fn -> Player.get_player!(player.id) end
    end

    test "change_player/1 returns a player changeset", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert %Ecto.Changeset{} = Player.change_player(player)
    end

    test "get_game_host/1 returns the game host", %{game: game} do
      {:ok, host} =
        Player.create_player(Map.merge(@valid_attrs, %{game_id: game.id, game_host: true}))

      {:ok, _regular_player} =
        Player.create_player(
          Map.merge(@valid_attrs, %{
            game_id: game.id,
            nickname: "RegularDet",
            avatar_file_name: "regular.png"
          })
        )

      assert Player.get_game_host(game.id) == host
    end

    test "set_as_host/1 sets player as host", %{game: game} do
      {:ok, player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert {:ok, updated_player} = Player.set_as_host(player)
      assert updated_player.game_host == true
    end

    test "nickname_available?/2 checks nickname availability", %{game: game} do
      assert Player.nickname_available?(game.id, "AvailableDetective") == true

      {:ok, _player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert Player.nickname_available?(game.id, "DetectiveSmith") == false
    end

    test "avatar_available?/2 checks avatar availability", %{game: game} do
      assert Player.avatar_available?(game.id, "available.png") == true

      {:ok, _player} = Player.create_player(Map.put(@valid_attrs, :game_id, game.id))
      assert Player.avatar_available?(game.id, "detective.png") == false
    end

    test "create_host_player/2 creates player as host", %{game: game} do
      assert {:ok, player} = Player.create_host_player(game, @valid_attrs)
      assert player.game_host == true
      assert player.game_id == game.id
    end

    test "list_human_players_for_game/1 returns only human players", %{game: game} do
      {:ok, human} =
        Player.create_player(Map.merge(@valid_attrs, %{game_id: game.id, is_robot: false}))

      {:ok, _robot} =
        Player.create_player(
          Map.merge(@valid_attrs, %{
            game_id: game.id,
            nickname: "RobotDetective",
            avatar_file_name: "robot.png",
            is_robot: true
          })
        )

      assert Player.list_human_players_for_game(game.id) == [human]
    end

    test "list_robot_players_for_game/1 returns only robot players", %{game: game} do
      {:ok, _human} =
        Player.create_player(Map.merge(@valid_attrs, %{game_id: game.id, is_robot: false}))

      {:ok, robot} =
        Player.create_player(
          Map.merge(@valid_attrs, %{
            game_id: game.id,
            nickname: "RobotDetective",
            avatar_file_name: "robot.png",
            is_robot: true
          })
        )

      assert Player.list_robot_players_for_game(game.id) == [robot]
    end
  end

  describe "validations" do
    setup do
      {:ok, game} = Game.create_game(%{invitation_code: "test123"})
      %{game: game}
    end

    test "validates nickname length", %{game: game} do
      long_nickname = String.duplicate("a", 16)
      attrs = %{nickname: long_nickname, avatar_file_name: "test.png", game_id: game.id}

      assert {:error, changeset} = Player.create_player(attrs)
      assert %{nickname: ["must be at most 15 characters long"]} = errors_on(changeset)
    end

    test "validates avatar_file_name length", %{game: game} do
      long_avatar = String.duplicate("a", 256)
      attrs = %{nickname: "TestDetective", avatar_file_name: long_avatar, game_id: game.id}

      assert {:error, changeset} = Player.create_player(attrs)
      assert %{avatar_file_name: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end

    test "validates nickname format rules", %{game: game} do
      # Test minimum length
      attrs = %{nickname: "a", avatar_file_name: "test.png", game_id: game.id}
      assert {:error, changeset} = Player.create_player(attrs)
      assert %{nickname: ["must be at least 2 characters long"]} = errors_on(changeset)

      # Test cannot start with underscore
      attrs = %{nickname: "_test", avatar_file_name: "test.png", game_id: game.id}
      assert {:error, changeset} = Player.create_player(attrs)
      assert %{nickname: ["cannot start with an underscore"]} = errors_on(changeset)

      # Test invalid characters (space)
      attrs = %{nickname: "test user", avatar_file_name: "test.png", game_id: game.id}
      assert {:error, changeset} = Player.create_player(attrs)

      assert %{nickname: ["can only contain letters, numbers, and underscores"]} =
               errors_on(changeset)

      # Test invalid characters (special symbols)
      attrs = %{nickname: "test@user", avatar_file_name: "test.png", game_id: game.id}
      assert {:error, changeset} = Player.create_player(attrs)

      assert %{nickname: ["can only contain letters, numbers, and underscores"]} =
               errors_on(changeset)

      # Test valid nickname with underscore (not at start)
      attrs = %{nickname: "test_user", avatar_file_name: "test.png", game_id: game.id}
      assert {:ok, _player} = Player.create_player(attrs)

      # Test valid nickname with numbers
      attrs = %{nickname: "test123", avatar_file_name: "test2.png", game_id: game.id}
      assert {:ok, _player} = Player.create_player(attrs)
    end

    test "enforces case-insensitive nickname uniqueness within game", %{game: game} do
      {:ok, game2} = Game.create_game(%{invitation_code: "test456"})

      # Create first player
      attrs1 = %{nickname: "TestUser", avatar_file_name: "test1.png", game_id: game.id}
      assert {:ok, _player1} = Player.create_player(attrs1)

      # Try to create player with same nickname in different case in same game
      attrs2 = %{nickname: "testuser", avatar_file_name: "test2.png", game_id: game.id}
      assert {:error, changeset} = Player.create_player(attrs2)
      assert %{nickname: ["is already taken in this game"]} = errors_on(changeset)

      # Should allow same nickname in different game
      attrs3 = %{nickname: "TestUser", avatar_file_name: "test3.png", game_id: game2.id}
      assert {:ok, _player3} = Player.create_player(attrs3)
    end

    test "requires game_id", %{game: _game} do
      attrs = %{nickname: "TestDetective", avatar_file_name: "test.png"}

      assert {:error, changeset} = Player.create_player(attrs)
      assert %{game_id: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
