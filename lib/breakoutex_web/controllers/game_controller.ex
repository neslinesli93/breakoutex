defmodule BreakoutexWeb.GameController do
  use BreakoutexWeb, :controller

  alias Phoenix.LiveView
  alias BreakoutexWeb.Live.Game

  def index(conn, _) do
    opts = [
      session: %{cookies: conn.cookies}
    ]

    LiveView.Controller.live_render(conn, Game, opts)
  end
end
