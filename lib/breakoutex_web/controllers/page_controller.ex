defmodule BreakoutexWeb.PageController do
  use BreakoutexWeb, :controller

  alias Phoenix.LiveView
  alias BreakoutexWeb.Live.Game

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def game(conn, _) do
    opts = [
      session: %{cookies: conn.cookies}
    ]

    LiveView.Controller.live_render(conn, Game, opts)
  end
end
