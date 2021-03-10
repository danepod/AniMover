defmodule AniMoverWeb.APIController do
  use AniMoverWeb, :controller

  def scan_now(conn, _params) do
    AniMover.FileWatcher.scan_now()

    send_resp(conn, :no_content, "")
  end
end
