defmodule BreakoutLiveWeb.PageController do
  use BreakoutLiveWeb, :controller

  alias Phoenix.LiveView

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def game(conn, _) do
    LiveView.Controller.live_render(
      conn,
      BreakoutLiveWeb.Live.Game,
      session: %{cookies: conn.cookies}
    )
  end
end
