defmodule CrimeToGo.Shared do
  @moduledoc """
  Shared utilities and common operations used across the application.

  This module contains reusable functions that help reduce code duplication
  and provide consistent behavior across different contexts.
  """

  @doc """
  Normalizes attribute maps by converting atom keys to string keys.

  This is commonly needed when working with forms that might have
  either atom or string keys, ensuring consistent data handling.

  ## Examples

      iex> normalize_attrs(%{name: "John", age: 30})
      %{"name" => "John", "age" => 30}
      
      iex> normalize_attrs(%{"name" => "John", "age" => 30})
      %{"name" => "John", "age" => 30}
  """
  @spec normalize_attrs(map()) :: map()
  def normalize_attrs(attrs) when is_map(attrs) do
    if Enum.any?(Map.keys(attrs), &is_atom/1) do
      for {key, val} <- attrs, into: %{} do
        {to_string(key), val}
      end
    else
      attrs
    end
  end

  @doc """
  Broadcasts a message to a PubSub topic with consistent error handling.

  ## Examples

      iex> broadcast_event("game:123", {:player_joined, %Player{}})
      :ok
  """
  @spec broadcast_event(String.t(), term()) :: :ok | {:error, term()}
  def broadcast_event(topic, message) do
    Phoenix.PubSub.broadcast(CrimeToGo.PubSub, topic, message)
  end

  @doc """
  Generates a random element from a list of valid options.

  ## Examples

      iex> random_from(~w(a b c d))
      "b"  # or any other element from the list
  """
  @spec random_from(list()) :: any()
  def random_from(list) when is_list(list) and length(list) > 0 do
    Enum.random(list)
  end

  @doc """
  Safely converts a value to string, handling nil values.

  ## Examples

      iex> safe_to_string(123)
      "123"
      
      iex> safe_to_string(nil)
      ""
  """
  @spec safe_to_string(any()) :: String.t()
  def safe_to_string(nil), do: ""
  def safe_to_string(value), do: to_string(value)

  @doc """
  Checks if a value exists in the database for the given query.

  This provides a consistent way to check for existence across contexts.
  """
  @spec exists?(Ecto.Query.t()) :: boolean()
  def exists?(query), do: CrimeToGo.Repo.exists?(query)
end
