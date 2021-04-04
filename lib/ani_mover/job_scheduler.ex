defmodule AniMover.JobScheduler do
  @moduledoc """
  This module takes care of querying the active jobs list to see if any of them match the given file.
  """

  require Logger

  alias AniMover.{Job, JobConfig}

  # TODO: Move this function into AniMover.JobConfig
  def active?(file_name) do
    JobConfig.get_jobs()
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

  defp prefix(pattern) do
    {pre_len, _} = AniMover.Renamer.split_input_pattern(pattern)
    {prefix, _} = String.split_at(pattern, pre_len)

    prefix
  end
end
