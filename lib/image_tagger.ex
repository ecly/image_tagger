defmodule ImageTagger do
  @moduledoc """
  ImageTagger keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias ImageTagger.ImageServer
  alias ImageTagger.ReviewServer

  @image_client Application.fetch_env!(:image_tagger, :image_client)

  @doc """
  Adds a review for the image associated with the given reviewer.
  """
  def review_image(reviewer, review) do
    ReviewServer.review_image(reviewer, review)
  end

  @doc """
  Returns the current amount of images in the ImageServer

  ## Examples
  iex> ImageTagger.images_left()
  100
  """
  def images_left(), do: ImageServer.get_count()

  @doc """
  A slightly hacky way to get the amount
  of people currently review, by getting the size
  of the ReviewServer's state.

  ## Examples
  iex> ImageTagger.reviewers_online()
  5

  """
  def reviewers_online() do
    ReviewServer.get_count()
  end

  @doc """
  Undoes the last review associated with the given reviewer.
  A result tuple is returned contanining a presigned_url of the
  image for which the tag was undone if any reviews are in the history
  of the given reviwer, otherwise an error is returned.

  ## Examples
  iex> ImageTagger.undo_last_review("reviewer_id")
  {:ok, "www.s3.amazon.com/some_key/some_image.png"}
  iex> ImageTagger.undo_last_review("reviewer_id")
  {:error, "no images in history for given reviewer"}
  """
  def undo_last_review(reviewer) do
    with {:ok, image} <- ReviewServer.undo_last_review(reviewer),
    do: @image_client.get_url(image)
  end


  @doc """
  Fetches an image to review for the given reviewer.
  The image is polled from the ImageServer and added
  to the Review Server.

  Returns both the image as a public url in an error tuple.
  {:ok public_url} || {:error, error}
  """
  def fetch_image_to_review(reviewer) do
    with {:ok, image} <- ImageServer.poll_image(),
         :ok <- ReviewServer.add_image(reviewer, image),
    do: @image_client.get_url(image)
  end
end
