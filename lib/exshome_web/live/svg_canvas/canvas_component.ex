defmodule ExshomeWeb.Live.SvgCanvas.CanvasComponent do
  @moduledoc """
  Generic SvgCanvas component.
  """

  defstruct [:id, :height, :width, :x, :y]

  @type t() :: %__MODULE__{
          id: String.t(),
          height: number(),
          width: number(),
          x: number(),
          y: number()
        }

  @callback to_component(any()) :: t()
  @callback render(any()) :: Phoenix.LiveView.Rendered.t()

  defmacro __using__(_) do
    quote do
      import Phoenix.LiveView.Helpers
      alias ExshomeWeb.Live.SvgCanvas.CanvasComponent
      @behaviour CanvasComponent
    end
  end
end
