defmodule ExshomeWeb.Live.ServicePreview do
  @moduledoc """
  Live view to support services preview.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    socket =
      assign(
        socket,
        time: DateTime.utc_now(),
        module: get_preview_module(socket)
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ExshomeWeb.ClockView.render("preview.html", assigns)
  end

  defp get_preview_module(%Socket{} = socket) do
    Exshome.Tag.tag_mapping()
    |> Map.fetch!(__MODULE__)
    |> Map.fetch!(socket.id)
  end
end
