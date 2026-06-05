defmodule BigzWeb.PageController do
  use BigzWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
