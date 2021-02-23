defmodule AniMover.Job do
  @enforce_keys [:pattern, :destination, :target_pattern]
  defstruct pattern: nil, destination: nil, target_pattern: nil, opts: []

  @type t() :: %__MODULE__{pattern: String.t(), destination: String.t(), target_pattern: String.t(), opts: Keyword.t()}

  def new(map = %{pattern: pattern, destination: destination, target_pattern: target_pattern}) do
    opts = map |> Map.get(:opts, []) |> Keyword.new()

    %__MODULE__{pattern: pattern, destination: destination, target_pattern: target_pattern, opts: opts}
  end
end
