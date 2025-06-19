# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Crime to Go is a multilingual multiplayer detective game built with Phoenix LiveView. The application supports real-time gameplay with chat functionality, avatar selection, and internationalization across 8 languages.

### Key Technologies
- **Phoenix 1.8** - Web framework with LiveView for real-time interactions
- **Ecto** - Database wrapper and query generator for PostgreSQL
- **Tailwind CSS** - Utility-first CSS framework for styling
- **Gettext** - Internationalization support for 8 languages
- **PubSub** - Real-time broadcasting for game events

### Code Organization Principles

The codebase follows these principles for maintainability:

1. **DRY (Don't Repeat Yourself)** - Common patterns are extracted into shared modules
2. **Single Responsibility** - Each module has a clear, focused purpose
3. **Consistent Error Handling** - Standardized error responses across the application
4. **Type Safety** - TypeSpecs are used for better documentation and tooling
5. **Internationalization First** - All user-facing text supports multiple languages

### Shared Modules

To reduce duplication, the application uses several shared modules:

- `CrimeToGo.Shared` - Common utilities and helper functions
- `CrimeToGo.Shared.Constants` - Application-wide constants and configuration
- `CrimeToGo.Shared.Validations` - Reusable validation functions
- `CrimeToGo.Shared.ErrorHandler` - Centralized error handling
- `CrimeToGoWeb.BaseLive` - Common LiveView patterns and utilities

## Development Commands

### Setup and Dependencies
- `mix setup` - Install dependencies, setup database, and build assets
- `mix deps.get` - Install Elixir dependencies only

### Running the Application
- `mix phx.server` - Start Phoenix server (available at localhost:4000)
- `iex -S mix phx.server` - Start server in interactive Elixir shell

### Testing
- `mix test` - Run all tests (automatically creates test DB and runs migrations)
- `mix test test/specific_test.exs` - Run a specific test file

### Use Generators
- `mix phx.gen.schema Blog.Post blog_posts title:string views:integer` to generate a new model (see https://hexdocs.pm/phoenix/1.8.0-rc.3/Mix.Tasks.Phx.Gen.Schema.html )
- `mix phx.gen.live Accounts User users name:string age:integer` Generates LiveView, templates, and context for a resource.

Always use generators if possible.

### Database
- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.setup` - Create database, run migrations, and seed data
- `mix ecto.reset` - Drop and recreate database with fresh data

### Assets
- `mix assets.setup` - Install Tailwind and esbuild if missing
- `mix assets.build` - Build CSS and JS assets for development
- `mix assets.deploy` - Build and minify assets for production

## Architecture Overview

This is a Phoenix 1.8 web application using:

**Core Stack:**
- Phoenix Framework with LiveView
- Ecto with PostgreSQL for database
- Tailwind CSS for styling
- esbuild for JavaScript bundling

**Key Modules:**
- `CrimeToGo.Application` - OTP application supervisor managing Repo, PubSub, Telemetry, and Endpoint
- `CrimeToGoWeb.Endpoint` - Phoenix endpoint handling HTTP requests
- `CrimeToGoWeb.Router` - Request routing with browser and API pipelines
- `CrimeToGo.Repo` - Ecto repository for database operations

**Directory Structure:**
- `lib/crime_to_go/` - Core business logic and contexts
- `lib/crime_to_go_web/` - Web layer (controllers, views, templates, components)
- `priv/repo/migrations/` - Database migration files
- `test/` - Test files mirroring lib structure
- `assets/` - Frontend assets (CSS, JS)
- `config/` - Application configuration files

The application uses Phoenix's standard MVC pattern with LiveView capabilities. Database operations go through Ecto contexts in the `CrimeToGo` namespace, while web-facing code lives in `CrimeToGoWeb`.

### Development Guidelines

When working on this codebase:

1. **Use Shared Modules** - Always check if functionality exists in shared modules before creating new code
2. **Follow Naming Conventions** - Use descriptive names that clearly indicate purpose
3. **Add Documentation** - Include @doc and @spec for public functions
4. **Validate Input** - Use shared validation functions for consistency
5. **Handle Errors Gracefully** - Use the ErrorHandler module for consistent error responses
6. **Test Thoroughly** - Ensure all changes are covered by tests
7. **Maintain I18n** - All user-facing strings must be translatable

### Performance Considerations

- Use preloading for associations to avoid N+1 queries
- Leverage PubSub for real-time updates instead of polling
- Keep LiveView assigns minimal - only store what's needed for rendering
- Use database indexes for frequently queried fields

### Security Notes

- All user input is validated through Ecto changesets
- Game codes exclude confusing characters (0, 1, 7) for usability
- Soft deletion is used for chat messages to maintain data integrity
- Foreign key constraints ensure referential integrity