defmodule AniMover.JobScheduler do
  require Logger

  alias AniMover.Job

  def active?(file_name) do
    load_jobs()
    |> Enum.find_value(fn job = %Job{pattern: pattern} ->
      pattern_prefix = prefix(pattern)
      prefix_length = String.length(pattern_prefix)
      file_name_prefix = String.slice(file_name, 0, prefix_length)

      if file_name_prefix == pattern_prefix do
        Logger.info("[Jobs] Found a job for \"#{file_name}\": #{pattern}")
        {:ok, job}
      end
    end)
    |> case do
      {:ok, job} -> {:ok, job}
      _ -> :no_job_found
    end
  end

  def load_jobs(job_file \\ "jobs.json") do
    job_file
    |> File.read!()
    |> Jason.decode!(keys: :atoms!)
    |> Map.fetch!(:jobs)
    |> Enum.map(&AniMover.Job.new(&1))
  rescue
    e in File.Error -> Logger.error("Failed to open file: #{inspect(e)}")
    e in Jason.DecodeError -> Logger.error("Failed to deserialize JSON file: #{inspect(e)}")
  end

  defp prefix(pattern) do
    {pre_len, _} = AniMover.Renamer.split_input_pattern(pattern)
    {prefix, _} = String.split_at(pattern, pre_len)

    prefix
  end
end
