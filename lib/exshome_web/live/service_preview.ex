defmodule ExshomeWeb.Live.ServicePreview do
  @moduledoc """
  Live view to support services preview.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket),
    do: {:ok, assign(socket, time: DateTime.utc_now())}

  @impl Phoenix.LiveView
  def render(assigns) do
    ExshomeWeb.ClockView.render("preview.html", assigns)
  end
end
