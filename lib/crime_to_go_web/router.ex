defmodule CrimeToGoWeb.Router do
  use CrimeToGoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CrimeToGoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CrimeToGoWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CrimeToGoWeb do
    pipe_through :browser

    # Route for setting locale
    post "/set_locale", PageController, :set_locale

    # Wrap all LiveViews in a live_session with locale mount and player status tracking
    live_session :default,
      on_mount: [
        {CrimeToGoWeb.LocaleHelpers, :default},
        {CrimeToGoWeb.LocaleHelpers, :player_status_tracking}
      ] do
      live "/", HomeLive.Index, :index

      # Game management routes
      live "/games", GameLive.Index, :index
      live "/games/new", GameLive.Index, :new
      live "/games/:id/host_dashboard", GameLive.HostDashboard, :host_dashboard
      live "/games/:id/lobby", GameLive.Lobby, :lobby

      # Player routes
      live "/games/:game_id/join", PlayerLive.Join, :join
      live "/games/:game_id/players", PlayerLive.Index, :index
      live "/games/:game_id/players/new", PlayerLive.Index, :new
      live "/games/:game_id/players/:id", PlayerLive.Show, :show

      # Chat routes
      live "/games/:game_id/chat", ChatLive.Index, :index
      live "/games/:game_id/chat_rooms/:id", ChatLive.Room, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", CrimeToGoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:crime_to_go, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CrimeToGoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
