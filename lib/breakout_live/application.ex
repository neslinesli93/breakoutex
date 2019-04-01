defmodule BreakoutLive.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      BreakoutLiveWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: BreakoutLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BreakoutLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
