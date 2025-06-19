defmodule CrimeToGo do
  @moduledoc """
  CrimeToGo is a multiplayer detective game application.

  This module serves as the main entry point for the application's business logic.
  The application is organized into several contexts that define the domain:

  ## Contexts

  - `CrimeToGo.Game` - Manages game lifecycle, state, and metadata
  - `CrimeToGo.Player` - Handles player management and game membership  
  - `CrimeToGo.Chat` - Provides chat functionality with public/private rooms

  ## Architecture

  The application follows Phoenix's context pattern, where each context
  encapsulates related functionality and provides a clean API for the web layer.
  Shared utilities are available in the `CrimeToGo.Shared` namespace.

  ## Key Features

  - Multi-language support with 8 supported languages
  - Real-time gameplay using Phoenix LiveView and PubSub
  - Secure game codes for easy game joining
  - Avatar selection and nickname management
  - Public and private chat systems
  """
end
