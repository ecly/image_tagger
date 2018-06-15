defmodule ImageTagger.ImageServer do
  @moduledoc """
  Server keeping track of all the images
  that are yet to be reviewed. It additionally keeps track
  of whether the current images in the server are all the images.
  This is done by checking whether the list of objects returned
  by Amazon's API is >= 999. list_objects is limited to 999,
  as such, when this many objects are returned, we assume there are more
  in the bucket. As such, whenever we're queried for amount of images,
  we'll return 999 if the list list_objects returned 999, even if there
  are currently less objects in the ImageServer.

  The servers updates the state once every
    `Application.fetch_env!(:image_tagger, :update_interval_seconds)
  seconds.
  """
  alias ExAws
  alias ImageTagger.ReviewServer
  use GenServer

  @doc """
  Starts the ImageServer as a singleton registered
  with the name of the module.

  ## Examples
  iex> {:ok, pid} = ImageTagger.ImageServer.start_link()
  {:ok, #PID<0.246.0>}

  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    state = fetch_state()
    schedule_update()
    {:ok, state}
  end

  @doc """
  Sends an update message to the ImageServer after
  the configured amount of seconds.
  """
  def schedule_update() do
    seconds = 1000 * Application.fetch_env!(:image_tagger, :update_interval_seconds)
    Process.send_after(self(), :update_state, seconds)
  end

  @doc """
  Fetches the keys of all the images currently in the review folder,
  meaning all images that are yet to be reviewed. This is returned as a tuple,
  where the first element indicates whether the list of images is truncated.

  Returns:
    {is_truncated, images}
  """
  def fetch_state() do
    bucket_name = Application.fetch_env!(:image_tagger, :bucket_name)
    image_folder = Application.fetch_env!(:image_tagger, :image_folder)

    {:ok, res} =
      bucket_name
      |> ExAws.S3.list_objects(prefix: image_folder)
      |> ExAws.request()

    is_truncated = res
      |> Map.get(:body)
      |> Map.get(:is_truncated)
      |> String.to_atom()

    # filter out folders and return a list of the keys
    images = res
      |> Map.get(:body)
      |> Map.get(:contents)
      |> Enum.filter(&(&1.size != "0"))
      |> Enum.map(& &1.key)

    {is_truncated, MapSet.new(images)}
  end

  @doc """
  Get all the images that are currently in the review folder,
  and subtracts all the images that are currently being reviewed by the
  ReviewServer.
  """
  def fetch_updated_state() do
    {is_truncated, images} = fetch_state()
    under_review = ReviewServer.get_images()
    filtered_images = MapSet.difference(images, MapSet.new(under_review))
    {is_truncated, filtered_images}
  end

  @doc """
  Updates the state of the ImageServer by querying S3 for images
  in the review folder and subtracting the images that are currently
  being reviewed.

  Additionally schedules a new update after the configured amount of seconds.
  """
  def handle_info(:update_state, _state) do
    updated_state = fetch_updated_state()
    schedule_update()
    {:noreply, updated_state}
  end

  @doc """
  Attemps to retrieve a random image for review from the ImageServer.
  Returns an error if there are no images left in the ImageServer.

  Returns: {:ok, image} || {:error, reason}
  """
  def handle_call(:poll_image, _from, {is_truncated, images} = state) do
    if MapSet.size(images) > 0 do
      image = Enum.random(images)
      new_images = MapSet.delete(images, image)
      {:reply, {:ok, image}, {is_truncated, new_images}}
    else
      {:reply, {:error, "No images left to review"}, state}
    end
  end

  @doc """
  Returns the size of the state.
  """
  def handle_call(:get_count, _from, {is_truncated, images} = state) do
    if is_truncated do
      {:reply, 999, state}
    else
      {:reply, MapSet.size(images), state}
    end
  end

  @doc """
  Returns the size of the state.
  """
  def handle_call({:add_image, image}, _from, {is_truncated, images}) do
    {:reply, :ok, {is_truncated, MapSet.put(images, image)}}
  end

  @doc """
  Retrieves the current amount of images in the ImageServer.

  ## Examples

  iex> ImageTagger.ImageServer.get_count()
  5
  """
  def get_count() do
    GenServer.call(__MODULE__, :get_count)
  end

  @doc """
  Adds an image to the ImageServer.
  This can be used by ReviewServer if an image
  is removed without being reviewed. It is however
  not necessary to do so, as the image will stay in the folder
  and be re-added by the next update_state(), but this makes
  the count update more quickly

  ## Examples

  iex> ImageTagger.ImageServer.add_image("to_review/image.png")
  """
  def add_image(image) do
    GenServer.call(__MODULE__, {:add_image, image})
  end

  @doc """
  Retrieves the next image to review from the server.
  The image is removed from the ImageServer.
  Returned as an error tuple.

  ## Examples

  iex> ImageTagger.ImageServer.poll_image()
  {:ok, image}
  iex> FortniteApi.AccessServer.pill_token()
  {:error, "No more images to review at the moment"}
  """
  def poll_image() do
    GenServer.call(__MODULE__, :poll_image)
  end
end
