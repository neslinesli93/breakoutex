defmodule BreakoutexWeb.GameController do
  use BreakoutexWeb, :controller

  alias Phoenix.LiveView
  alias BreakoutexWeb.Live.Game

  def index(conn, _) do
    LiveView.Controller.live_render(conn, Game)
  end
end
