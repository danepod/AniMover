defmodule AniMover.JobConfig do
  use GenServer

  require Logger

  defstruct watched_folders: [], jobs: []

  @type t() :: %{
          watched_folders: [Path.t()],
          jobs: [AniMover.Job.t()]
        }

  # Public interface ---------------------------------------------------------------------------------------------------
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def get_watched_folders, do: GenServer.call(__MODULE__, :get_watched_folders)

  def get_jobs, do: GenServer.call(__MODULE__, :get_jobs)

  # GenServer implementation -------------------------------------------------------------------------------------------
  def init(args \\ []) do
    job_file_location = Keyword.get(args, :job_file, "jobs.json")

    job_file = load_file(job_file_location)

    watched_folders = Map.fetch!(job_file, :watched_folders)
    jobs = job_file |> Map.fetch!(:jobs) |> Enum.map(&AniMover.Job.new(&1))

    {:ok, %__MODULE__{watched_folders: watched_folders, jobs: jobs}}
  end

  def handle_call(:get_watched_folders, _from, state = %{watched_folders: watched_folders}),
    do: {:reply, watched_folders, state}

  def handle_call(:get_jobs, _from, state = %{jobs: jobs}), do: {:reply, jobs, state}

  # Helpers ------------------------------------------------------------------------------------------------------------
  defp load_file(job_file) do
    job_file |> File.read!() |> Jason.decode!(keys: :atoms!)
  rescue
    e in File.Error -> Logger.error("Failed to open file: #{inspect(e)}")
    e in Jason.DecodeError -> Logger.error("Failed to deserialize JSON file: #{inspect(e)}")
  end
end
