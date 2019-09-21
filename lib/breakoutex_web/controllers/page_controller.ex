defmodule BreakoutexWeb.PageController do
  use BreakoutexWeb, :controller

  alias Phoenix.LiveView

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def game(conn, _) do
    LiveView.Controller.live_render(
      conn,
      BreakoutexWeb.Live.Game,
      session: %{cookies: conn.cookies}
    )
  end
end
