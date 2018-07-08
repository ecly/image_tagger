defmodule ImageTagger.ReviewServerTest do
  use ExUnit.Case, async: false

  alias ImageTagger.ImageServer
  alias ImageTagger.ReviewServer

  @id "test_reviewer_id"
  @image "some_image_path"

  setup do
    ImageServer.reset()
    ReviewServer.reset()
  end

  test "count returns expected amount" do
    :ok = ReviewServer.add_image(@id, @image)
    assert 1 == ReviewServer.get_count()
    :ok = ReviewServer.remove_reviewer(@id)
    assert 0 == ReviewServer.get_count()
  end

  test "reviewers removed from review_server have their current image added to image_server" do
    :ok = ReviewServer.add_image(@id, @image)
    prior_count = ImageServer.get_count()
    :ok = ReviewServer.remove_reviewer(@id)
    assert prior_count + 1 == ImageServer.get_count()
  end

  test "get_images returns all images in the review_server, both history and current" do
    img1 = "img1"
    img2 = "img2"
    img3 = "img3"
    :ok = ReviewServer.add_image("1", img1)
    :ok = ReviewServer.review_image("1", :bad)
    :ok = ReviewServer.add_image("1", img2)
    :ok = ReviewServer.add_image("2", img3)

    images = ReviewServer.get_images()
    assert length(images) == 3
    assert img1 in images
    assert img2 in images
    assert img3 in images
  end

  test "undoing review for reviewer returns last reviewed_image" do
    :ok = ReviewServer.add_image(@id, @image)
    ReviewServer.review_image(@id, :bad)
    assert {:ok, @image} == ReviewServer.undo_last_review(@id)
  end

  test "undoing review for reviewer with no history returns error" do
    :ok = ReviewServer.add_image(@id, @image)
    assert {:error, "no images in history for the given reviewer"} == ReviewServer.undo_last_review(@id)
  end

  test "undoing history for non-existing reviewer returns error" do
    assert {:error, "no reviewer with given id"} == ReviewServer.undo_last_review("gibberish")
  end
end
