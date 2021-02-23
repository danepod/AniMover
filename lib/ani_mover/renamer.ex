defmodule AniMover.Renamer do
  @moduledoc """
  This module contains the logic which determines the new file name when given a template.
  """
  @number_regex ~r/#+/

  # TODO: Make clear that files are only matched using their prefix

  defmacro match_number(name, pre_len, num_len) do
    quote do
      try do
        <<pre::binary-size(unquote(pre_len)), n::binary-size(unquote(num_len)), _suf::binary>> = unquote(name)

        String.to_integer(n)
      rescue
        MatchError -> throw(:no_match)
        ArgumentError -> throw(:no_match)
      end
    end
  end

  @doc """
  Constructs a new filename out of the given original filename and the input and output patterns.

  ## Options:
    - `offset`: Takes a positive or negative integer to change the resulting episode number.

  ## Examples

      iex> rename(
        "[SubGroup]_Attack_on_Human_-_11_[Blu-ray_1080p_Hi10P_FLAC][61DCE29F].mkv",
        "[SubGroup]_Attack_on_Human_-_##_[Blu-ray_1080p_Hi10P_FLAC][61DCE29F].mkv",
        "Attack on Human S01E##.mkv"
      )
      {:ok, "Attack on Human S01E11.mkv"}

      iex> rename(
        "[SubGroup] Shingeki no Ningen (The Final Season) - 65 (1080p) [F542501D].mkv",
        "[SubGroup] Shingeki no Ningen (The Final Season) - ## (1080p) [F542501D].mkv",
        "Attack on Human S04E##.mkv",
        offset: -59
      )
      {:ok, "Attack on Human S04E06.mkv"}
  """
  def rename(original_name, old_name_pattern, new_name_pattern, opts \\ []) do
    {pre_len, num_len} = split_input_pattern(old_name_pattern)
    {match_length, new_name_pattern} = prepare_pattern(new_name_pattern)

    new_name =
      original_name
      |> match_number(pre_len, num_len)
      |> apply_offset(opts)
      |> zero_padding(match_length)
      |> build_new_name(new_name_pattern)

    {:ok, new_name}
  catch
    :no_match -> {:error, :no_match}
  end

  def split_input_pattern(original_name_pattern) do
    [{pre_len, num_len}] = Regex.run(@number_regex, original_name_pattern, return: :index)

    {pre_len, num_len}
  end

  defp prepare_pattern(new_name_pattern) do
    [{_index, match_length}] = Regex.run(@number_regex, new_name_pattern, return: :index)
    updated_pattern = String.replace(new_name_pattern, @number_regex, "<%= num %>")

    {match_length, updated_pattern}
  end

  defp apply_offset(number, opts) do
    offset = Keyword.get(opts, :offset, 0)

    number + offset
  end

  defp zero_padding(number_string, padding_length),
    do: number_string |> Integer.to_string() |> String.pad_leading(padding_length, "0")

  defp build_new_name(num, new_name_pattern), do: EEx.eval_string(new_name_pattern, num: num)
end
