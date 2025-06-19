defmodule CrimeToGo.Shared.ErrorHandler do
  @moduledoc """
  Centralized error handling utilities for consistent error responses
  across the application.

  This module provides standardized ways to handle common error scenarios
  like validation failures, not found errors, and authorization issues.
  """

  import Phoenix.LiveView, only: [put_flash: 3, push_navigate: 2]
  use CrimeToGoWeb, :verified_routes

  @doc """
  Handles Ecto.NoResultsError with a standard "not found" response.

  ## Examples

      handle_not_found_error(socket, "Game not found")
  """
  @spec handle_not_found_error(Phoenix.LiveView.Socket.t(), String.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def handle_not_found_error(socket, message \\ nil) do
    error_message = message || "Resource not found"

    {:ok,
     socket
     |> put_flash(:error, error_message)
     |> push_navigate(to: ~p"/")}
  end

  @doc """
  Handles authorization errors with a standard unauthorized response.

  ## Examples

      handle_unauthorized_error(socket, "You are not authorized to view this page")
  """
  @spec handle_unauthorized_error(Phoenix.LiveView.Socket.t(), String.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def handle_unauthorized_error(socket, message \\ nil) do
    error_message = message || "You are not authorized to access this resource"

    {:ok,
     socket
     |> put_flash(:error, error_message)
     |> push_navigate(to: ~p"/")}
  end

  @doc """
  Handles validation errors from Ecto changesets.

  ## Examples

      handle_validation_error(socket, changeset)
  """
  @spec handle_validation_error(Phoenix.LiveView.Socket.t(), Ecto.Changeset.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_validation_error(socket, changeset) do
    error_message = format_changeset_errors(changeset)

    {:noreply,
     socket
     |> put_flash(:error, error_message)
     |> Phoenix.Component.assign(changeset: changeset, form: Phoenix.Component.to_form(changeset))}
  end

  @doc """
  Formats changeset errors into a human-readable string.

  ## Examples

      iex> format_changeset_errors(changeset)
      "Name is required. Email must be valid."
  """
  @spec format_changeset_errors(Ecto.Changeset.t()) :: String.t()
  def format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      field_name = field |> to_string() |> String.replace("_", " ") |> String.capitalize()
      "#{field_name} #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join(". ")
    |> case do
      "" -> "Invalid input provided"
      message -> message
    end
  end

  @doc """
  Logs errors with context information for debugging.

  ## Examples

      log_error(error, %{context: "game_creation", user_id: user_id})
  """
  @spec log_error(Exception.t() | String.t(), map()) :: :ok
  def log_error(error, context \\ %{}) do
    require Logger

    error_message =
      case error do
        %{message: message} -> message
        error when is_binary(error) -> error
        error -> inspect(error)
      end

    Logger.error("Application error: #{error_message}", context)
  end

  @doc """
  Wraps a function call with error handling, providing a fallback result.

  ## Examples

      with_error_fallback(fn -> dangerous_operation() end, {:error, :failed})
  """
  @spec with_error_fallback(function(), any()) :: any()
  def with_error_fallback(fun, fallback) do
    try do
      fun.()
    rescue
      error ->
        log_error(error)
        fallback
    end
  end
end
