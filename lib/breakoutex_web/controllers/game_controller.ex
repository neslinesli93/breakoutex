defmodule BreakoutexWeb.GameController do
  use BreakoutexWeb, :controller

  alias BreakoutexWeb.Live.Game
  alias Phoenix.LiveView

  def index(conn, _) do
    LiveView.Controller.live_render(conn, Game)
  end
end
