defmodule ImageTagger.Images.S3Client do
  @moduledoc """
  An Image Client implementation for S3 interfacing.
  URLs a created using presigned URLs.
  Uses ExAws.
  """

  @behaviour ImageTagger.Images.Behaviour

  alias ExAws

  @doc """
  Fetches the keys of all the images currently in the review folder,
  meaning all images that are yet to be reviewed. This is returned as a tuple,
  where the first element indicates whether the list of images is truncated.

  Returns:
    {is_truncated, images}
  """
  def fetch_images() do
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
  Moves the given image from src into the given folder
  """
  def move_image_to_folder(image_src, folder) do
    bucket = Application.fetch_env!(:image_tagger, :bucket_name)
    name = Path.basename(image_src)
    image_dst = Path.join(folder, name)
    bucket |> ExAws.S3.put_object_copy(image_dst, bucket, image_src) |> ExAws.request()
    bucket |> ExAws.S3.delete_object(image_src) |> ExAws.request()
  end


  @doc """
  Generate a public URL for an image
  """
  def get_url(image) do
    config = ExAws.Config.new(:s3)
    bucket = Application.fetch_env!(:image_tagger, :bucket_name)
    ExAws.S3.presigned_url(config, :get, bucket, image)
  end
end
