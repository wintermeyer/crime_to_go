defmodule CrimeToGo.GameTest do
  use CrimeToGo.DataCase

  alias CrimeToGo.Game
  alias CrimeToGo.Game.Game, as: GameSchema

  describe "games" do
    @valid_attrs %{invitation_code: "test123"}
    @invalid_attrs %{invitation_code: nil}

    test "list_games/0 returns all games" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert Game.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert Game.get_game!(game.id) == game
    end

    test "get_game_by_code/1 returns the game with given code" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert Game.get_game_by_code(game.game_code) == game
    end

    test "get_game_by_code/1 returns nil for nonexistent code" do
      assert Game.get_game_by_code("nonexistent") == nil
    end

    test "create_game/1 with valid data creates a game" do
      assert {:ok, %GameSchema{} = game} = Game.create_game(@valid_attrs)
      assert game.invitation_code == "test123"
      assert game.state == "pre_game"
      assert String.length(game.game_code) == 12
      assert Regex.match?(~r/^[2-9]{12}$/, game.game_code)
    end

    test "create_game/1 generates unique game codes" do
      assert {:ok, game1} = Game.create_game(@valid_attrs)
      assert {:ok, game2} = Game.create_game(@valid_attrs)
      assert game1.game_code != game2.game_code
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      {:ok, game} = Game.create_game(@valid_attrs)
      update_attrs = %{invitation_code: "updated123"}

      assert {:ok, %GameSchema{} = game} = Game.update_game(game, update_attrs)
      assert game.invitation_code == "updated123"
    end

    test "update_game/2 with invalid data returns error changeset" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Game.update_game(game, @invalid_attrs)
      assert game == Game.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert {:ok, %GameSchema{}} = Game.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Game.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert %Ecto.Changeset{} = Game.change_game(game)
    end

    test "start_game/1 starts a game" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert {:ok, updated_game} = Game.start_game(game)
      assert updated_game.state == "active"
      assert updated_game.start_at != nil
    end

    test "end_game/1 ends a game" do
      {:ok, game} = Game.create_game(@valid_attrs)
      assert {:ok, updated_game} = Game.end_game(game)
      assert updated_game.state == "post_game"
      assert updated_game.end_at != nil
    end
  end

  describe "game code generation" do
    test "generates codes without 0, 1, or 7" do
      for _ <- 1..50 do
        code = GameSchema.generate_game_code()
        assert String.length(code) == 12
        assert not String.contains?(code, "0")
        assert not String.contains?(code, "1")
        assert not String.contains?(code, "7")
        assert Regex.match?(~r/^[2-9]{12}$/, code)
      end
    end

    test "generates different codes each time" do
      codes = for _ <- 1..10, do: GameSchema.generate_game_code()
      assert Enum.uniq(codes) == codes
    end
  end

  describe "game states" do
    test "validates game state values" do
      {:ok, game} = Game.create_game(@valid_attrs)

      # Valid states
      assert {:ok, _} = Game.update_game(game, %{state: "pre_game"})
      assert {:ok, _} = Game.update_game(game, %{state: "active"})
      assert {:ok, _} = Game.update_game(game, %{state: "post_game"})

      # Invalid state
      assert {:error, changeset} = Game.update_game(game, %{state: "invalid"})
      assert %{state: ["is invalid"]} = errors_on(changeset)
    end
  end
end
