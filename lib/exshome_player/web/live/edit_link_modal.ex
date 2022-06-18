defmodule ExshomePlayer.Web.Live.EditLinkModal do
  @moduledoc """
  Modal for editing links.
  """
  use ExshomeWeb.Live.AppPage, dependencies: []

  alias ExshomePlayer.Schemas.Track

  @fields [
    title: [],
    path: []
  ]

  @impl LiveView
  def mount(_params, session, %Socket{} = socket) do
    socket =
      socket
      |> assign(:error, nil)
      |> assign(:fields, @fields)
      |> fetch_track_from_session(session)

    {:ok, socket}
  end

  @impl LiveView
  def handle_event("validate", %{"data" => data}, %Socket{} = socket) do
    data = sanitize_data(data)
    changeset = socket.assigns.changeset

    new_changeset =
      changeset.data
      |> Track.changeset(data)
      |> Map.put(:action, changeset.action)

    {:noreply, assign(socket, :changeset, new_changeset)}
  end

  @impl LiveView
  def handle_event("save", %{"data" => data}, %Socket{} = socket) do
    data = sanitize_data(data)

    track = socket.assigns.changeset.data

    result =
      if track.id do
        Track.update(track, data)
      else
        Track.create(data)
      end

    socket =
      case result do
        {:ok, _result} -> close_modal(socket)
        {:error, changeset} -> assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  defp sanitize_data(data) do
    allowed_fields = for {field, _} <- @fields, do: "#{field}"

    for {field, value} <- data, field in allowed_fields, into: %{"type" => "url"} do
      {field, value}
    end
  end

  defp fetch_track_from_session(%Socket{} = socket, session) do
    case get_track_by_session(session) do
      {:ok, track} -> assign(socket, :changeset, Track.changeset(track))
      {:error, reason} -> assign(socket, :error, reason)
    end
  end

  def get_track_by_session(%{"track_id" => track_id}) do
    case Track.get!(track_id) do
      %Track{type: :url} = track -> {:ok, track}
      _ -> {:error, "unable to edit data for this track"}
    end
  end

  def get_track_by_session(_session) do
    {:ok, %Track{type: :url, path: ""}}
  end
end
