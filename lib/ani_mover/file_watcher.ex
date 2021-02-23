defmodule AniMover.FileWatcher do
  use GenServer

  require Logger

  alias AniMover.Job

  @watched_events [:created, :renamed]

  # Public interface ---------------------------------------------------------------------------------------------------
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def scan_now, do: GenServer.call(__MODULE__, :scan_now)

  # GenServer implementation -------------------------------------------------------------------------------------------
  def init(args \\ []) do
    args = Keyword.put_new(args, :dirs, load_configuration())

    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid, watched_folders: Keyword.get(args, :dirs)}}
  end

  def handle_call(:scan_now, _from, state = %{watched_folders: watched_folders}) do
    # TODO: This might take longer than 5 seconds, files should be processed in a separate process
    Enum.each(watched_folders, &scan_folder/1)

    {:reply, :ok, state}
  end

  def handle_info({:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid} = state) do
    cond do
      Enum.member?(events, :modified) and File.dir?(path) -> scan_folder(path)
      Enum.any?(events, fn event -> event in @watched_events end) -> process_file(path)
      true -> nil
    end

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    # This executes when the file monitor is stopped
    {:noreply, state}
  end

  defp load_configuration(job_file \\ "jobs.json") do
    job_file
    |> File.read!()
    |> Jason.decode!(keys: :atoms!)
    |> Map.fetch!(:watched_folders)
  rescue
    e in File.Error -> Logger.error("Failed to open file: #{inspect(e)}")
    e in Jason.DecodeError -> Logger.error("Failed to deserialize JSON file: #{inspect(e)}")
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
