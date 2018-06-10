defmodule ImageTaggerWeb.Presence.LeaveTracker do
  @moduledoc """
  Simple GenServer for handling Phoenix Presence,
  and keeping track of Reviewers's leaving, for which it will ensure
  that they are removed from the ReviewServer.
  """
  use GenServer
  require Logger
  alias ImageTagger.ReviewServer
  alias ImageTaggerWeb.Endpoint
  alias ImageTaggerWeb.ReviewChannel
  alias Phoenix.Socket.Broadcast

  @doc """
  Starts the LeaveTracker as a singleton registered
  with the name of the module.

  ## Examples
  iex> {:ok, pid} = ImageTaggerWeb.Presence.LeaveTracker.start_link
  {:ok, #PID<0.246.0>}

  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    {:ok, nil}
  end

  @doc """
  Call event for tracking a given channel, from the given id.
  """
  def handle_call({:track, id}, _from, state) do
    :ok = Endpoint.subscribe("reviewers:" <> id, [])
    {:reply, :ok, state}
  end

  @doc """
  Handles presence_diff events with no leaves.
  When there's no leaves in the given event, there's nothing to do be done.
  """
  def handle_info(%Broadcast{event: "presence_diff", payload: %{leaves: %{} = leaves}}, state)
      when leaves == %{} do
    {:noreply, state}
  end

  @doc """
  Handles presence_diff events with leaves.
  When a reviewers leaves the channel, we unsubscribe to his topic, and
  remove him from the state in the review server.
  """
  def handle_info(%Broadcast{event: "presence_diff", payload: %{leaves: leaves}}, state) do
    [id | _] =
      leaves
      |> Map.values()
      |> Enum.map(fn %{metas: [%{id: id}]} -> id end)

    ReviewServer.remove_reviewer(id)
    {:noreply, state}
  end

  @doc false
  def handle_info(_, state) do
    {:noreply, state}
  end

  @doc """
  Tracks the given reviewer such that we from within the LeaveTracker
  will be notified if the user has dropped their connection, and
  can do the necessary cleaning up.
  ## Examples
  iex> ImageTaggerWeb.Presence.LeaveTracker.track("reviewer_id")
  """
  def track(id) do
    GenServer.call(__MODULE__, {:track, id})
  end
end
