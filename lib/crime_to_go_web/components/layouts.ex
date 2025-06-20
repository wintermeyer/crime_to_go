defmodule CrimeToGoWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use CrimeToGoWeb, :html
  import CrimeToGoWeb.LocaleHelpers

  embed_templates "layouts/*"

  def app(assigns) do
    # Default locale if not set
    assigns = assign_new(assigns, :locale, fn -> "en" end)
    # Default current_player to nil if not set
    assigns = assign_new(assigns, :current_player, fn -> nil end)

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
                <.icon name="hero-home" class="w-4 h-4" /> {gettext("Home")}
              </a>
            </li>
            <li>
              <a href="/games" class="flex items-center gap-2">
                <.icon name="hero-play" class="w-4 h-4" /> {gettext("Games")}
              </a>
            </li>
          </ul>
        </div>
        
    <!-- Logo and Brand -->
        <a href="/" class="flex items-center gap-2">
          <img src={~p"/images/logo.svg"} width="32" height="32" alt={gettext("CrimeToGo")} />
          <span class="text-lg font-bold hidden sm:block">{gettext("CrimeToGo")}</span>
        </a>
      </div>

      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <li>
            <a href="/" class="flex items-center gap-2">
              <.icon name="hero-home" class="w-4 h-4" /> {gettext("Home")}
            </a>
          </li>
          <li>
            <a href="/games" class="flex items-center gap-2">
              <.icon name="hero-play" class="w-4 h-4" /> {gettext("Games")}
            </a>
          </li>
        </ul>
      </div>

      <div class="navbar-end">
        <div class="flex items-center gap-2">
          <!-- Player Dropdown or Language Selector -->
          <%= if @current_player do %>
            <!-- Player Dropdown Menu -->
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-sm flex items-center gap-2">
                <%= if @current_player.avatar_file_name do %>
                  <div class="relative">
                    <img
                      src={~p"/images/avatars/#{@current_player.avatar_file_name}"}
                      alt={@current_player.nickname}
                      class="w-6 h-6 rounded-full"
                    />
                    <div class={[
                      "absolute -bottom-0.5 -right-0.5 w-2 h-2 rounded-full border border-base-100",
                      if(@current_player.status == "online", do: "bg-success", else: "bg-error")
                    ]}>
                    </div>
                  </div>
                <% else %>
                  <.icon name="hero-user-circle" class="w-5 h-5" />
                <% end %>
                <span class="hidden sm:inline">{@current_player.nickname}</span>
                <.icon name="hero-chevron-down" class="w-3 h-3" />
              </div>
              <ul
                tabindex="0"
                class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
              >
                <!-- Profile -->
                <li>
                  <a href="#" class="flex items-center gap-2">
                    <.icon name="hero-user" class="w-4 h-4" />
                    {gettext("My Profile")}
                  </a>
                </li>
                
    <!-- Change Language -->
                <li>
                  <details>
                    <summary class="flex items-center gap-2">
                      <.icon name="hero-language" class="w-4 h-4" />
                      {gettext("Language")}
                    </summary>
                    <ul class="p-2">
                      <li :for={{code, name} <- locale_names()}>
                        <form method="post" action="/set_locale" style="display: inline;">
                          <input
                            type="hidden"
                            name="_csrf_token"
                            value={Phoenix.Controller.get_csrf_token()}
                          />
                          <input type="hidden" name="locale" value={code} />
                          <button
                            type="submit"
                            class={[
                              "w-full text-left flex items-center gap-2 p-2 hover:bg-base-200 rounded",
                              @locale == code && "bg-base-200 font-medium"
                            ]}
                          >
                            <span class="text-lg">{locale_flag(code)}</span>
                            {name}
                          </button>
                        </form>
                      </li>
                    </ul>
                  </details>
                </li>

                <div class="divider my-1"></div>
                
    <!-- Leave Game -->
                <li>
                  <a href="/" class="flex items-center gap-2 text-error">
                    <.icon name="hero-arrow-left-on-rectangle" class="w-4 h-4" />
                    {gettext("Leave Game")}
                  </a>
                </li>
              </ul>
            </div>
          <% else %>
            <!-- Language Selector (when not in game) -->
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                <.icon name="hero-language" class="w-4 h-4" />
                <span class="hidden sm:inline ml-1">
                  {locale_flag(@locale)} {String.upcase(@locale)}
                </span>
              </div>
              <ul
                tabindex="0"
                class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
              >
                <li :for={{code, name} <- locale_names()}>
                  <form method="post" action="/set_locale" style="display: inline;">
                    <input
                      type="hidden"
                      name="_csrf_token"
                      value={Phoenix.Controller.get_csrf_token()}
                    />
                    <input type="hidden" name="locale" value={code} />
                    <button
                      type="submit"
                      class={[
                        "w-full text-left flex items-center gap-2 p-2 hover:bg-base-200 rounded",
                        @locale == code && "bg-base-200 font-medium"
                      ]}
                    >
                      <span class="text-lg">{locale_flag(code)}</span>
                      {name}
                    </button>
                  </form>
                </li>
              </ul>
            </div>
          <% end %>
          
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
          <img src={~p"/images/logo.svg"} width="24" height="24" alt={gettext("CrimeToGo")} />
          <span class="font-semibold">{gettext("CrimeToGo")}</span>
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
