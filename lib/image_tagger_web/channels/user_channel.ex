defmodule ImageTaggerWeb.UserChannel do
  alias ImageTagger
  use Phoenix.Channel

  @new_image_event "new_image"

  def join("room:" <> id, _message, socket) do
    socket = assign(socket, :id, id)
    {:ok, socket}
  end

  def handle_in("poll_image", _msg, socket) do
    case ImageTagger.fetch_image_to_review(socket.assigns.id) do
      {:ok, url} ->
        count = ImageTagger.images_left()
        push(socket, @new_image_event, %{"url" => url, "count" => count})
        {:noreply, socket}
      _otherwise -> {:noreply, socket}
    end
  end

  def handle_in("submit_review", %{"review" => review_string}, socket) do
    id = socket.assigns.id
    review = String.to_existing_atom(review_string)
    ImageTagger.review_image(id, review)
    {:noreply, socket}
  end
end
