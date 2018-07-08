defmodule ImageTagger.Images.Behaviour do
  @doc """
  Moves the image at `img_path` into the given `folder`
  """
  @callback move_image_to_folder(img_path :: String.t, folder :: String.t) :: {:ok, term} | {:error, String.t}
  @doc """
  Fetches the images to be tagged.
  Returned as a tuple of the form:
    {is_truncated :: bolean, images :: MapSet}
  """
  @callback fetch_images() :: {boolean, struct}
end
