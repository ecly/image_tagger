defmodule ImageTagger do
  @moduledoc """
  ImageTagger keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias ImageTagger.ImageServer
  alias ImageTagger.ReviewServer
  alias ExAws

  @doc """
  Adds a review for the image associated with the given reviewer.
  """
  def review_image(reviewer, review) do
    ReviewServer.review_image(reviewer, review)
  end

  def images_left() do
    ImageServer.get_count()
  end

  # Generate a public URL for an image
  defp get_public_url(image) do
    config = ExAws.Config.new(:s3)
    bucket = Application.fetch_env!(:image_tagger, :bucket_name)
    ExAws.S3.presigned_url(config, :get, bucket, image)
  end

  @doc """
  Fetches an image to review for the given reviewer.
  The image is polled from the ImageServer and added
  to the Review Server.

  Returns both the image as a public url in an error tuple.
  {:ok public_url} || {:error, error}
  """
  def fetch_image_to_review(reviewer) do
    case ImageServer.poll_image() do
      {:ok, image} ->
        :ok = ReviewServer.add_image(reviewer, image)
        get_public_url(image)
      {:error, reason} -> {:error, reason}
    end
  end
end
