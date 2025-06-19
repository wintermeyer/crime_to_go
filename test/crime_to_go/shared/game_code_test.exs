defmodule CrimeToGo.Shared.GameCodeTest do
  use ExUnit.Case
  alias CrimeToGo.Shared.GameCode
  alias CrimeToGo.Shared.Constants

  describe "generate/0" do
    test "generates a game code with correct length" do
      code = GameCode.generate()
      assert String.length(code) == Constants.game_code_length()
    end

    test "generates a game code with only valid digits" do
      code = GameCode.generate()
      valid_digits = Constants.game_code_digits() |> MapSet.new()
      
      code
      |> String.graphemes()
      |> Enum.each(fn digit ->
        assert MapSet.member?(valid_digits, digit), 
               "Generated code contains invalid digit: #{digit}"
      end)
    end

    test "generated game code passes validation" do
      code = GameCode.generate()
      assert GameCode.valid?(code)
    end

    test "generates different codes on subsequent calls" do
      codes = Enum.map(1..10, fn _ -> GameCode.generate() end)
      unique_codes = codes |> Enum.uniq()
      
      # All codes should be unique (very high probability)
      assert length(unique_codes) == length(codes)
    end
  end

  describe "valid?/1" do
    test "returns true for freshly generated codes" do
      code = GameCode.generate()
      assert GameCode.valid?(code)
    end

    test "returns false for codes with wrong length" do
      refute GameCode.valid?("123")
      refute GameCode.valid?("12345678901234567890")
    end

    test "returns false for codes with invalid digits" do
      # Contains '0', '1', '7' which are excluded
      refute GameCode.valid?("012345678901")
      refute GameCode.valid?("234567890123")
      refute GameCode.valid?("234567781234")
    end

    test "returns false for codes with invalid checksum" do
      # Take a valid code and change the last digit
      valid_code = GameCode.generate()
      {base, _} = String.split_at(valid_code, -1)
      
      # Find a different valid digit for the checksum
      valid_digits = Constants.game_code_digits()
      current_checksum = GameCode.checksum_digit(valid_code)
      different_digit = Enum.find(valid_digits, &(&1 != current_checksum))
      
      invalid_code = base <> different_digit
      refute GameCode.valid?(invalid_code)
    end

    test "returns false for non-string input" do
      refute GameCode.valid?(nil)
      refute GameCode.valid?(123)
      refute GameCode.valid?([])
    end
  end

  describe "base_code/1" do
    test "extracts base code correctly" do
      code = GameCode.generate()
      base = GameCode.base_code(code)
      
      assert String.length(base) == Constants.game_code_length() - 1
      assert base == String.slice(code, 0..-2//1)
    end
  end

  describe "checksum_digit/1" do
    test "extracts checksum digit correctly" do
      code = GameCode.generate()
      checksum = GameCode.checksum_digit(code)
      
      assert String.length(checksum) == 1
      assert checksum == String.slice(code, -1..-1)
    end
  end

  describe "checksum consistency" do
    test "generated code parts can be reconstructed and validated" do
      # Generate a valid code
      code = GameCode.generate()
      base = GameCode.base_code(code)
      checksum = GameCode.checksum_digit(code)
      
      # Reconstruct the code from its parts
      reconstructed = base <> checksum
      
      # Should be identical and valid
      assert reconstructed == code
      assert GameCode.valid?(reconstructed)
    end

    test "modifying base code invalidates checksum" do
      # Generate a valid code
      code = GameCode.generate()
      base = GameCode.base_code(code)
      checksum = GameCode.checksum_digit(code)
      
      # Change one digit in the base (use a different valid digit)
      valid_digits = Constants.game_code_digits()
      first_digit = String.first(base)
      different_digit = Enum.find(valid_digits, &(&1 != first_digit))
      
      modified_base = different_digit <> String.slice(base, 1..-1//1)
      modified_code = modified_base <> checksum
      
      # Modified code should be invalid (wrong checksum)
      refute GameCode.valid?(modified_code)
    end
  end
end