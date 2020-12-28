defmodule BreakoutexWeb.Components.ActiveUsers do
  use BreakoutexWeb, :live_component
  @moduledoc """
    A small LiveView that shows the active players of the game
  """

  def render(assigns) do
    ~L"""
      <h6>Users online:</h6>
      <%= for {user_id, user} <- @users do %>
        <%= if user_id == @current_user_id do %>
          <span class="me"><%= user[:name] %></span>
        <% else %>
          <%= user[:name] %>
        <% end %>
        (<%= DateTime.from_unix!(user[:joined_at]) %>)
        Lvl: <%= user[:level] %>
        Points: <%= user[:points] %>
        <br />
      <% end %>
    """
  end

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
