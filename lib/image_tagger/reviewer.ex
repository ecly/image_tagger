defmodule ImageTagger.Reviewer do
  @moduledoc """
  Module representing a Reviewer struct.
  """
  @doc """
  id      => The ID of the given reviewers ReviewerChannel.
  history => The reviewer's recent reviews.
  current => The image the reviewer is currently reviewing.

  """
  defstruct id: nil,
            history: [],
            current: nil
end
