defmodule CrimeToGoWeb.PageController do
  use CrimeToGoWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def set_locale(conn, %{"locale" => locale}) do
    conn = CrimeToGoWeb.Plugs.Locale.put_locale(conn, locale)

    case get_req_header(conn, "referer") do
      [referer] -> redirect(conn, external: referer)
      _ -> redirect(conn, to: "/")
    end
  end
end
