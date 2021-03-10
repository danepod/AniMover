defmodule AniMoverWeb.PageController do
  use AniMoverWeb, :controller

  def index(conn, _params) do
    config = AniMover.JobConfig.get_config()

    render(conn, "index.html", config: config)
  end
end
