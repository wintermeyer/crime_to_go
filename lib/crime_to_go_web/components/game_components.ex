defmodule CrimeToGoWeb.GameComponents do
  @moduledoc """
  Game-specific UI components for consistent mobile-optimized design.
  """
  
  use Phoenix.Component
  use CrimeToGoWeb, :verified_routes
  use Gettext, backend: CrimeToGoWeb.Gettext

  @doc """
  Renders a compact, mobile-optimized player list.
  
  ## Examples
  
      <.mobile_player_list players={@players} show_status={true} />
  """
  attr :players, :list, required: true
  attr :show_status, :boolean, default: false
  attr :title, :string, default: nil
  
  def mobile_player_list(assigns) do
    ~H"""
    <div class="card bg-base-100">
      <div class="card-body p-4">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-sm font-semibold">
            <%= @title || gettext("Players") %> (<%= length(@players) %>)
          </h2>
          <%= if @show_status do %>
            <%= if length(@players) >= 2 do %>
              <div class="badge badge-success badge-sm">{gettext("Ready")}</div>
            <% else %>
              <div class="badge badge-warning badge-sm">{gettext("Waiting")}</div>
            <% end %>
          <% end %>
        </div>
        <div class="space-y-2">
          <%= for player <- @players do %>
            <div class="flex items-center gap-2 p-2 bg-base-200 rounded-lg">
              <img
                src={~p"/images/avatars/#{player.avatar_file_name}"}
                alt={player.nickname}
                class="w-8 h-8 rounded-full"
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium truncate">{player.nickname}</p>
                <%= if player.game_host do %>
                  <p class="text-xs text-primary">{gettext("Host")}</p>
                <% end %>
              </div>
              <!-- Online indicator for lobby -->
              <%= if @show_status do %>
                <div class="w-2 h-2 bg-success rounded-full"></div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a mobile-optimized game code display with copy functionality.
  
  ## Examples
  
      <.mobile_game_code code={@game.game_code} />
  """
  attr :code, :string, required: true
  attr :primary, :boolean, default: true
  
  def mobile_game_code(assigns) do
    assigns = assign(assigns, :formatted_code, format_game_code(assigns.code))
    
    ~H"""
    <div class={[
      "card border mb-3",
      if(@primary, do: "bg-primary/10 border-primary/20", else: "bg-base-100 border-base-200")
    ]}>
      <div class="card-body p-4 text-center">
        <div class={[
          "text-xs font-medium mb-1",
          if(@primary, do: "text-primary", else: "text-base-content/70")
        ]}>
          {gettext("Game Code")}
        </div>
        <div class={[
          "font-mono font-bold tracking-widest mb-2",
          if(@primary, do: "text-2xl text-primary", else: "text-xl text-base-content")
        ]}>
          {@formatted_code}
        </div>
        <button
          class={[
            "btn btn-sm w-full",
            if(@primary, do: "btn-primary", else: "btn-outline")
          ]}
          onclick={"navigator.clipboard.writeText('#{@code}').then(() => {
            document.getElementById('copy-feedback-#{String.replace(@code, " ", "")}').classList.remove('hidden');
            setTimeout(() => document.getElementById('copy-feedback-#{String.replace(@code, " ", "")}').classList.add('hidden'), 1500);
          })"}
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
          {gettext("Copy Code")}
        </button>
        <p id={"copy-feedback-#{String.replace(@code, " ", "")}"} class="text-xs text-success mt-1 hidden">
          {gettext("Copied!")}
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a collapsible sharing options section.
  
  ## Examples
  
      <.mobile_sharing_options join_url={@join_url} />
  """
  attr :join_url, :string, required: true
  
  def mobile_sharing_options(assigns) do
    ~H"""
    <div class="card bg-base-100 mb-3">
      <div class="card-body p-4">
        <div class="collapse collapse-arrow">
          <input type="checkbox" class="peer" />
          <div class="collapse-title text-sm font-medium p-0 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z" />
            </svg>
            {gettext("More Sharing Options")}
          </div>
          <div class="collapse-content p-0 pt-3">
            <!-- Copy Link -->
            <div class="mb-3">
              <label class="text-xs font-medium text-base-content/70">{gettext("Join Link")}</label>
              <div class="flex gap-2 mt-1">
                <input
                  id="join-url-input"
                  type="text"
                  readonly
                  value={@join_url}
                  class="input input-bordered input-sm flex-1 text-xs font-mono"
                />
                <button
                  class="btn btn-outline btn-sm"
                  onclick="navigator.clipboard.writeText(document.getElementById('join-url-input').value).then(() => {
                    document.getElementById('copy-url-feedback').classList.remove('hidden');
                    setTimeout(() => document.getElementById('copy-url-feedback').classList.add('hidden'), 1500);
                  })"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </button>
              </div>
              <p id="copy-url-feedback" class="text-xs text-success mt-1 hidden">{gettext("Link copied!")}</p>
            </div>
            
            <!-- QR Code -->
            <div class="text-center">
              <label class="text-xs font-medium text-base-content/70">{gettext("QR Code")}</label>
              <div class="flex justify-center mt-2">
                <div class="bg-white p-2 rounded-lg border">
                  <div style="width: 120px; height: 120px;">
                    {Phoenix.HTML.raw(EQRCode.encode(@join_url) |> EQRCode.svg(width: 120, viewbox: true))}
                  </div>
                </div>
              </div>
              <p class="text-xs text-base-content/60 mt-2">{gettext("Scan to join instantly")}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions
  defp format_game_code(code) do
    code
    |> String.graphemes()
    |> Enum.chunk_every(4)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(" ")
  end
end