defmodule ImageTagger.ImageServer do
  @moduledoc """
  Server keeping track of all the images
  that are yet to be reviewed.
  """
  alias ExAws
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

  def fetch_images() do
    bucket_name = Application.fetch_env!(:image_tagger, :bucket_name)
    image_folder = Application.fetch_env!(:image_tagger, :image_folder)
    {:ok, res} =
      bucket_name
      |> ExAws.S3.list_objects(prefix: image_folder)
      |> ExAws.request

    # filter out folders and return a list of the keys
    res
    |> Map.get(:body)
    |> Map.get(:contents)
    |> Enum.filter(&(&1.size != "0"))
    |> Enum.map(&(&1.key))
  end

  @doc false
  def init(:ok) do
    images = fetch_images()
    {:ok, MapSet.new(images)}
  end

  @doc """
  Attemps to retrieve an image for review from the ImageServer
  Returns: {:ok, image} || {:error, reason}
  """
  def handle_call({:poll_image}, _from, state) do
    if MapSet.size(state) > 0 do
      image = Enum.at(state, 0)
      new_state = MapSet.delete(state, image)
      {:reply, {:ok, image}, new_state}
    else
      {:reply, {:error, "No images left to review"}, state}
    end
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
    GenServer.call(__MODULE__, {:poll_image})
  end
end
