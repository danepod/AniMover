defmodule AniMover.FileWatcher do
  @moduledoc """
  This module sets up a file-watcher and receives its events.
  """

  use GenServer

  require Logger

  alias AniMover.Job

  @watched_events [:created, :renamed]

  # Public interface ---------------------------------------------------------------------------------------------------
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def scan_now, do: GenServer.call(__MODULE__, :scan_now)

  # GenServer implementation -------------------------------------------------------------------------------------------
  def init(args \\ []) do
    args = Keyword.put_new(args, :dirs, AniMover.JobConfig.get_watched_folders())

    # TODO: inode-tools' file watching doesn't work inside Docker, prepare a polling solution
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid, watched_folders: AniMover.JobConfig.get_watched_folders()}}
  end

  def handle_call(:scan_now, _from, state = %{watched_folders: watched_folders}) do
    # TODO: This might take longer than 5 seconds, files should be processed in a separate process
    Enum.each(watched_folders, &scan_folder/1)

    {:reply, :ok, state}
  end

  def handle_info(state = {:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid}) do
    cond do
      Enum.member?(events, :modified) and File.dir?(path) -> scan_folder(path)
      Enum.any?(events, fn event -> event in @watched_events end) -> process_file(path)
      true -> nil
    end

    {:noreply, state}
  end

  def handle_info(state = {:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid}) do
    # This executes when the file monitor is stopped
    {:noreply, state}
  end

  defp scan_folder(path),
    do: path |> File.ls!() |> Enum.each(fn file -> path |> Path.join(file) |> process_file() end)

  defp process_file(path) do
    if File.exists?(path) and !File.dir?(path) do
      Logger.info("[FileWatcher] Found file #{path}")

      path
      |> Path.basename()
      |> AniMover.JobScheduler.active?()
      |> case do
        {:ok, job = %Job{}} ->
          AniMover.FileMover.rename_and_move(path, job.pattern, job.destination, job.target_pattern, job.opts)

        _ ->
          nil
      end
    end
  end
end
