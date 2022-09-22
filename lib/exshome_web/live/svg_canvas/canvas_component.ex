defmodule ExshomeWeb.Live.SvgCanvas.CanvasComponent do
  @moduledoc """
  Generic SvgCanvas component.
  """

  @callback id(any()) :: String.t()
  @callback render(map()) :: Phoenix.LiveView.Rendered.t()

  defmacro __using__(_) do
    quote do
      import Phoenix.Component
      import Phoenix.LiveView
      alias ExshomeWeb.Live.SvgCanvas.CanvasComponent
      alias ExshomeWeb.SvgCanvasView

      @behaviour CanvasComponent
    end
  end
end
