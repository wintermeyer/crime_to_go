defmodule CrimeToGoWeb.PlayerLive.Index do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
