defmodule BreakoutLiveWeb.Router do
  use BreakoutLiveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BreakoutLiveWeb do
    pipe_through :browser

    get "/", PageController, :game
  end
end
