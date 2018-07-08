defmodule ImageTagger.Images.Behaviour do
  @moduledoc """
  Behaviour to be implemented by Image clients.
  These clients are responsible for interfacing with whatever
  storage is used for the images to be tagged. This includes fetching images
  as well as moving images, which is how they will be tagged.

  """
  @doc """
  Moves the image at `img_path` into the given `folder`
  """
  @callback move_image_to_folder(img_path :: String.t(), folder :: String.t()) ::
              {:ok, term} | {:error, String.t()}
  @doc """
  Fetches the images to be tagged.
  Returned as a tuple of the form:
    {is_truncated :: bolean, images :: MapSet}
  """
  @callback fetch_images() :: {boolean, struct}

  @doc """
  Creates a publicly accessible url for the given image.
  For a locally hosted instance, this could simply be the relative path,
  which could then be server by Phoenix.
  For S3 this would be a function creating a presigned URL for the given image.
  """
  @callback get_url(img_path :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
