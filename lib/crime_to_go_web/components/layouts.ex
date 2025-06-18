defmodule CrimeToGoWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use CrimeToGoWeb, :html

  embed_templates "layouts/*"

  def app(assigns) do
    ~H"""
    <!-- Navigation Bar -->
    <header class="navbar bg-base-100 shadow-sm border-b border-base-300 px-4 sm:px-6 lg:px-8">
      <div class="navbar-start">
        <!-- Mobile menu button -->
        <div class="dropdown lg:hidden">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
            <.icon name="hero-bars-3" class="w-5 h-5" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
          >
            <li>
              <a href="/" class="flex items-center gap-2">
                <.icon name="hero-home" class="w-4 h-4" /> Home
              </a>
            </li>
            <li>
              <a href="/games" class="flex items-center gap-2">
                <.icon name="hero-play" class="w-4 h-4" /> Games
              </a>
            </li>
          </ul>
        </div>
        
    <!-- Logo and Brand -->
        <a href="/" class="flex items-center gap-2">
          <img src={~p"/images/logo.svg"} width="32" height="32" alt="CrimeToGo" />
          <span class="text-lg font-bold hidden sm:block">CrimeToGo</span>
        </a>
      </div>

      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <li>
            <a href="/" class="flex items-center gap-2">
              <.icon name="hero-home" class="w-4 h-4" /> Home
            </a>
          </li>
          <li>
            <a href="/games" class="flex items-center gap-2">
              <.icon name="hero-play" class="w-4 h-4" /> Games
            </a>
          </li>
        </ul>
      </div>

      <div class="navbar-end">
        <div class="flex items-center gap-2">
          <!-- Language Selector -->
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
              <.icon name="hero-language" class="w-4 h-4" />
              <span class="hidden sm:inline ml-1">EN</span>
            </div>
            <ul
              tabindex="0"
              class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
            >
              <li><a href="#" phx-click="set_language" phx-value-lang="en">English</a></li>
              <li><a href="#" phx-click="set_language" phx-value-lang="de">Deutsch</a></li>
              <li><a href="#" phx-click="set_language" phx-value-lang="fr">Français</a></li>
              <li><a href="#" phx-click="set_language" phx-value-lang="es">Español</a></li>
              <li><a href="#" phx-click="set_language" phx-value-lang="tr">Türkçe</a></li>
              <li><a href="#" phx-click="set_language" phx-value-lang="ru">Русский</a></li>
              <li><a href="#" phx-click="set_language" phx-value-lang="uk">Українська</a></li>
            </ul>
          </div>
          
    <!-- Notification Bell -->
          <button class="btn btn-ghost btn-sm btn-circle relative">
            <.icon name="hero-bell" class="w-4 h-4" />
            <span class="absolute -top-1 -right-1 badge badge-xs badge-error hidden">3</span>
          </button>
        </div>
      </div>
    </header>

    <!-- Flash Messages Area -->
    <div class="sticky top-0 z-40">
      <.flash_group flash={@flash} />
    </div>

    <!-- Main Content -->
    <main class="min-h-screen bg-base-50">
      <div class="container mx-auto px-4 py-6 sm:px-6 lg:px-8">
        {@inner_content}
      </div>
    </main>

    <!-- Footer -->
    <footer class="footer footer-center p-6 bg-base-200 text-base-content border-t border-base-300">
      <div>
        <div class="flex items-center gap-2 mb-2">
          <img src={~p"/images/logo.svg"} width="24" height="24" alt="CrimeToGo" />
          <span class="font-semibold">CrimeToGo</span>
        </div>
        <p class="text-sm text-base-content/70">
          © 2024 CrimeToGo. All rights reserved.
        </p>
        <p class="text-xs text-base-content/50 mt-1">
          A multiplayer detective game built with Phoenix LiveView
        </p>
      </div>
    </footer>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="space-y-0">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-[33%] h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-[33%] [[data-theme=dark]_&]:left-[66%] transition-[left]" />

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})} class="flex p-2">
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})} class="flex p-2">
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})} class="flex p-2">
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
