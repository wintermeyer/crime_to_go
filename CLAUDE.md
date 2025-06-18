# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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