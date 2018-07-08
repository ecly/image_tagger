defmodule ImageTagger.ImageServerTest do
  use ExUnit.Case, async: false

  alias ImageTagger.ImageServer
  alias ImageTagger.ReviewServer

  setup do
    ImageServer.reset()
    ReviewServer.reset()
  end

  test "get count returns expected amount" do
    # test_client starts it off with 100 images
    assert 100 == ImageServer.get_count()
    ImageServer.add_image("some extra image")
    assert 101 == ImageServer.get_count()
    _ = ImageServer.poll_image()
    assert 100 == ImageServer.get_count()
  end

  test "poll image returns result tuple with image_path" do
    # test_client starts it off with 100 images
    {:ok, some_image} = ImageServer.poll_image()
    assert is_binary(some_image)
  end

  test "poll image returns error when empty" do
    # empty the server so we can test for error
    Enum.each(1..100, fn _ -> ImageServer.poll_image() end)
    assert {:error, "no images left to review"} == ImageServer.poll_image()
  end

  test "fetch updated state substracts images from review server" do
    image = "image1"
    ReviewServer.add_image("some_reviewer", image)
    {_is_truncated, images} = ImageServer.fetch_updated_state()
    assert 99 == MapSet.size(images)
    refute MapSet.member?(images, image)
  end
end
