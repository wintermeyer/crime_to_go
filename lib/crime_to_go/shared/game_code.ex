defmodule CrimeToGo.Shared.GameCode do
  @moduledoc """
  Game code generation and validation with checksum support.
  
  This module provides functions to generate game codes with built-in checksums
  for validation without database lookup. The game codes exclude confusing digits
  (0, 1, 7) for better user experience.
  """

  alias CrimeToGo.Shared.Constants

  @doc """
  Generates a new game code with checksum.
  
  The game code consists of:
  - 11 random digits from the valid digit set (2,3,4,5,6,8,9)
  - 1 checksum digit calculated using Luhn algorithm adapted for our digit set
  
  ## Examples
  
      iex> game_code = CrimeToGo.Shared.GameCode.generate()
      iex> String.length(game_code)
      12
      iex> CrimeToGo.Shared.GameCode.valid?(game_code)
      true
  """
  @spec generate() :: String.t()
  def generate do
    valid_digits = Constants.game_code_digits()
    base_length = Constants.game_code_length() - 1  # Reserve 1 digit for checksum
    
    # Generate base code (11 digits)
    base_code = 
      1..base_length
      |> Enum.map(fn _ -> Enum.random(valid_digits) end)
      |> Enum.join()
    
    # Calculate and append checksum
    checksum = calculate_checksum(base_code)
    base_code <> checksum
  end

  @doc """
  Validates a game code using its checksum.
  
  Returns true if the game code has the correct format and valid checksum,
  false otherwise. This allows validation without database lookup.
  
  ## Examples
  
      iex> CrimeToGo.Shared.GameCode.valid?("234565432345")
      false  # Invalid checksum
      
      iex> valid_code = CrimeToGo.Shared.GameCode.generate()
      iex> CrimeToGo.Shared.GameCode.valid?(valid_code)
      true
  """
  @spec valid?(String.t()) :: boolean()
  def valid?(game_code) when is_binary(game_code) do
    with true <- String.length(game_code) == Constants.game_code_length(),
         true <- contains_only_valid_digits?(game_code),
         {base_code, provided_checksum} <- String.split_at(game_code, -1),
         calculated_checksum <- calculate_checksum(base_code) do
      provided_checksum == calculated_checksum
    else
      _ -> false
    end
  end
  def valid?(_), do: false

  @doc """
  Extracts the base code (without checksum) from a game code.
  
  ## Examples
  
      iex> CrimeToGo.Shared.GameCode.base_code("234565432345")
      "23456543234"
  """
  @spec base_code(String.t()) :: String.t()
  def base_code(game_code) when is_binary(game_code) do
    {base, _checksum} = String.split_at(game_code, -1)
    base
  end

  @doc """
  Extracts the checksum digit from a game code.
  
  ## Examples
  
      iex> CrimeToGo.Shared.GameCode.checksum_digit("234565432345")
      "5"
  """
  @spec checksum_digit(String.t()) :: String.t()
  def checksum_digit(game_code) when is_binary(game_code) do
    {_base, checksum} = String.split_at(game_code, -1)
    checksum
  end

  # Private functions

  # Calculate checksum using modified Luhn algorithm for our digit set
  defp calculate_checksum(base_code) do
    valid_digits = Constants.game_code_digits()
    digit_to_index = valid_digits |> Enum.with_index() |> Map.new()
    index_to_digit = valid_digits |> Enum.with_index() |> Map.new(fn {digit, index} -> {index, digit} end)
    digit_count = length(valid_digits)
    
    # Convert digits to indices for calculation
    indices = 
      base_code
      |> String.graphemes()
      |> Enum.map(&Map.get(digit_to_index, &1, 0))
    
    # Apply modified Luhn algorithm
    sum = 
      indices
      |> Enum.reverse()  # Process from right to left
      |> Enum.with_index()
      |> Enum.reduce(0, fn {digit_index, position}, acc ->
        if rem(position, 2) == 1 do
          # Double every second digit (from right), wrap around our digit set
          doubled = rem(digit_index * 2, digit_count)
          acc + doubled
        else
          acc + digit_index
        end
      end)
    
    # Calculate checksum digit
    checksum_index = rem(digit_count - rem(sum, digit_count), digit_count)
    Map.get(index_to_digit, checksum_index)
  end

  # Check if game code contains only valid digits
  defp contains_only_valid_digits?(game_code) do
    valid_digits_set = Constants.game_code_digits() |> MapSet.new()
    
    game_code
    |> String.graphemes()
    |> Enum.all?(&MapSet.member?(valid_digits_set, &1))
  end
end