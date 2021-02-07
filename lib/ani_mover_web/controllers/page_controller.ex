defmodule AniMoverWeb.PageController do
  use AniMoverWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
