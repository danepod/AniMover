defmodule AniMover.FileMover do
  @moduledoc """
  This module takes care of moving files from one place in the filesystem to another.
  """

  require Logger

  @doc """
  Moves and renames the input file. Uses an input pattern to determine the placement of the episode number. A second
  pattern is then used as a basis for the new file name.

  ## Examples

      iex> rename_and_move(
        "/Users/Foobert/Downloads/[SubGroup]_Attack_on_Human_-_11_[Blu-ray_1080p_Hi10P_FLAC][61DCE29F].mkv",
        "[SubGroup]_Attack_on_Human_-_##_[Blu-ray_1080p_Hi10P_FLAC][61DCE29F].mkv",
        "/Users/Foobert/Anime/Attack on Human/Season 01",
        "Attack on Human S01E##.mkv"
      )
      :ok
  """
  def rename_and_move(old_path, old_name_pattern, new_path, new_name_pattern, opts \\ []) do
    with {:ok, new_filename} <-
           AniMover.Renamer.rename(Path.basename(old_path), old_name_pattern, new_name_pattern, opts),
         new_path = Path.join(new_path, new_filename),
         {time_µs, :ok} <- move_file(old_path, new_path) do
      Logger.info(~s([FileMover] Moving file "#{old_path}" to "#{new_path}" took #{time_µs / 1_000_000}s))
    else
      {:error, :no_match} ->
        Logger.info("[FileMover] Aborted moving file \"#{old_path}\": Name didn't match pattern fully.")

      {{:error, reason}, _time_µs} ->
        Logger.error(~s([FileMover] Moving file "#{old_path}" to "#{new_path}" failed: #{reason}))
    end
  end

  defp move_file(old_path, new_path) do
    :timer.tc(fn ->
      case File.rename(old_path, new_path) do
        :ok -> :ok
        {:error, :exdev} -> fallback_copy_then_delete(old_path, new_path)
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  # This is used when the origin and target paths are on different devices
  defp fallback_copy_then_delete(old_path, new_path) do
    with false <- File.exists?(new_path),
         :ok <- File.cp(old_path, new_path) do
      File.rm(old_path)
    else
      true -> {:error, :file_already_exists}
      err -> err
    end
  end
end
