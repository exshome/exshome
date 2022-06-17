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
  def mount(_params, _session, %Socket{} = socket) do
    socket =
      socket
      |> assign(:changeset, Track.changeset(%Track{type: :url, path: ""}))
      |> assign(:fields, @fields)

    {:ok, socket}
  end

  @impl LiveView
  def handle_event("validate", %{"data" => data}, %Socket{} = socket) do
    data = sanitize_data(data)
    {:noreply, update(socket, :changeset, &Track.changeset(&1, data))}
  end

  @impl LiveView
  def handle_event("save", %{"data" => data}, %Socket{} = socket) do
    data = sanitize_data(data)

    socket =
      case Track.create(data) do
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
end
