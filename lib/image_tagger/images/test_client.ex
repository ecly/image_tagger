defmodule ImageTagger.Images.TestClient do
  @behaviour ImageTagger.Images.Behaviour

  @doc """
  Always return a MapSet of 100 images without truncation during testing.
  """
  def fetch_images() do
    images = Enum.map(1..100, &("image#{&1}"))
    {false, MapSet.new(images)}
  end

  @doc """
  Test implementations of move_image_to_folder with various hardcoded
  patterns to be used during testing.
  """
  def move_image_to_folder("invalid_img", _folder), do: {:error, "Bad image path"}
  def move_image_to_folder(_image_src, "invalid_folder"), do: {:error, "Bad folder path"}
  def move_image_to_folder(_image_src, _folder), do: {:ok, "testing"}
end
