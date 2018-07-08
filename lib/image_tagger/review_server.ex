defmodule ImageTagger.ReviewServer do
  @moduledoc """
  Server keeping track of all the images
  that are currently being reviewed.

  Implemented as a map of %{<reviewer id> => {current, history}},
  where current is the path to the image currently being reviewed,
  and history is a keyword list with the last X images of the form {image, tag}.
  """
  alias ExAws
  alias ImageTagger.ImageServer
  alias ImageTagger.Reviewer
  use GenServer

  @image_client Application.fetch_env!(:image_tagger, :image_client)

  @doc """
  Starts the ImageServer as a singleton registered
  with the name of the module.

  ## Examples
  iex> {:ok, pid} = ImageTagger.ReviewServer.start_link()
  {:ok, #PID<0.246.0>}

  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    {:ok, %{}}
  end

  @doc """
  Archives the given image, copying it to the folder associated
  with the given tag.
  """
  def archive_image(image, tag) when is_atom(tag) do
    folder = Application.fetch_env!(:image_tagger, tag)
    @image_client.move_image_to_folder(image, folder)
  end

  @doc """
  Adds an image to the ReviewServer signifying that it
  is currently being reviewed. If the Reviewer is already associated
  with an image, that image is added back into the ImageServer.

  Returns :ok
  """
  def handle_call({:add_image, reviewer_id, image}, _from, state) do
    if Map.has_key?(state, reviewer_id) do
      %Reviewer{current: current} = state[reviewer_id]

      if current != nil do
        :ok = ImageServer.add_image(current)
      end
      {:reply, :ok, put_in(state[reviewer_id].current, image)}
    else
      {:reply, :ok, Map.put(state, reviewer_id, %Reviewer{id: reviewer_id, current: image})}
    end
  end

  @doc """
  Adds a review for an image, causing it to be removed
  from the ReviewServer and moved to the appropriate folder
  based on the review.

  Expects the reviewer and the review. The image will be found
  based on the reviewer's id.

  Returns: :ok
  """
  def handle_call({:review_image, reviewer_id, tag}, _from, state) do
    case state[reviewer_id] do
      nil ->
        {:reply, :ok, state}

      # If the given reviewer is associated with no image, do nothing
      %Reviewer{current: nil} ->
        {:reply, :ok, state}

      %Reviewer{current: current, history: history} = reviewer ->
        max_history = Application.fetch_env!(:image_tagger, :history_size)

        review = {current, tag}

        # If history exceeds max_history, we archive the oldest image in the history.
        if length(history) >= max_history do
          [{oldest_img, oldest_tag} | tail] = history
          archive_image(oldest_img, oldest_tag)
          new_reviewer = %Reviewer{reviewer | current: nil, history: tail ++ [review]}
          {:reply, :ok, put_in(state[reviewer_id], new_reviewer)}
        else
          new_reviewer = %Reviewer{reviewer | current: nil, history: history ++ [review]}
          {:reply, :ok, put_in(state[reviewer_id], new_reviewer)}
        end
    end
  end

  @doc """
  Returns the size of the state, in the form of the amount of reviewers
  currently stored by the ReviewServer.
  """
  def handle_call(:get_count, _from, state) do
    {:reply, map_size(state), state}
  end

  @doc """
  Returns the values of the state, meaning all the images
  associated with the currently connected reviewers. This includes
  both the image currently being reviewed by each reviewer and their history.
  """
  def handle_call(:get_images, _from, state) do
    current_images =
      state
      |> Map.values()
      |> Enum.map(fn reviewer -> reviewer.current end)
      |> Enum.filter(&(&1 != nil))

    history_images =
      state
      |> Map.values()
      |> Enum.flat_map(fn reviewer -> Keyword.keys(reviewer.history) end)

    {:reply, current_images ++ history_images, state}
  end

  @doc """
  Returns the values of the state, meaning all the images
  associated with the currently connected reviewers. This includes
  both the image currently being reviewed by each reviewer and their history.
  """
  def handle_call({:undo_last_review, reviewer_id}, _from, state) do
    case state[reviewer_id] do
      nil ->
        {:reply, {:error, "no reviewer with given id"}, state}

      %Reviewer{history: []} ->
        {:reply, {:error, "no images in history for the given reviewer"}, state}

      %Reviewer{current: current, history: history} = reviewer ->
        if current != nil do
          :ok = ImageServer.add_image(current)
        end

        {undone_img, _tag} = List.last(history)
        new_history = Enum.drop(history, -1)
        new_reviewer = %Reviewer{reviewer | current: undone_img, history: new_history}
        new_state = put_in(state[reviewer_id], new_reviewer)
        {:reply, {:ok, undone_img}, new_state}
    end
  end

  @doc """
  Removes the given reviewer from the state.
  If the reviewer is associated with an image,
  that image is added back into the ImageServer.
  """
  def handle_call({:remove_reviewer, reviewer_id}, _from,  state) do
    if Map.has_key?(state, reviewer_id) do
      %Reviewer{current: current, history: history} = state[reviewer_id]

      if current != nil do
        :ok = ImageServer.add_image(current)
      end

      Enum.each(history, fn {img, tag} -> archive_image(img, tag) end)
    end

    {:reply, :ok, Map.delete(state, reviewer_id)}
  end

  @doc """
  Discards the entire state of the ReviewServer and sets the state
  to be an empty Map. Used for testing.
  """
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{}}
  end

  @doc """
  Retrieves the current amount of images in the ImageServer.

  ## Examples

  iex> ImageTagger.ReviewServer.get_count()
  5
  """
  def get_count() do
    GenServer.call(__MODULE__, :get_count)
  end

  @doc """
  Retrieves all the keys from the state,
  meaning all the keys for the images associated
  with all the active reviewers.

  ## Examples

  iex> ImageTagger.ReviewServer.get_images()
  ["image1", "image2", "image3"]
  """
  def get_images() do
    GenServer.call(__MODULE__, :get_images)
  end

  @doc """
  Removes the reviewer associated with the given id from the state.

  ## Examples

  iex> ImageTagger.ReviewServer.remove_reviewer("reviewer_id")
  """
  def remove_reviewer(id) do
    GenServer.call(__MODULE__, {:remove_reviewer, id})
  end

  @doc """
  Adds a review for an image.
  The image is removed from the ReviewServer and moved to
  a folder according to the reivew.

  ## Examples

  iex> ImageTagger.ReviewServer.review_image("some_user_id", :good)
  :ok
  iex> ImageTagger.ReviewServer.review_image("some_user_id", :bad)
  :ok
  """
  def review_image(reviewer, review) do
    GenServer.call(__MODULE__, {:review_image, reviewer, review})
  end

  @doc """
  Adds a review for an image.
  The image is removed from the ReviewServer and moved to
  a folder according to the reivew.

  ## Examples

  iex> ImageTagger.ReviewServer.undo_last_review("some_user_id")
  {:ok, "to_review/some_image.png"}
  :ok
  iex> ImageTagger.ReviewServer.undo_last_review("some_user_id")
  {:error, "no images in history for given reviewer"}
  """
  def undo_last_review(reviewer) do
    GenServer.call(__MODULE__, {:undo_last_review, reviewer})
  end

  @doc """
  Associates a reviewer with an image.
  currently being reviewed. If the reviewer is currently
  not reviewing anything, nothing is done.

  ## Examples

  iex> ImageTagger.ReviewServer.add_image("some_user_id", "to_review/image1234.png")
  :ok
  """
  def add_image(reviewer, image) do
    GenServer.call(__MODULE__, {:add_image, reviewer, image})
  end

  @doc """
  Resets the state of the ReviewServer removing all reviewers and images from it.
  They are not added back into the ImageServer as this is intended for testing.
  """
  def reset() do
    GenServer.call(__MODULE__, :reset)
  end
end
