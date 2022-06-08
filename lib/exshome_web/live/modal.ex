defmodule ExshomeWeb.Live.Modal do
  @moduledoc """
  Adds modal support for every live page.
  """
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  defstruct [:module, :assigns]

  @type t() :: %__MODULE__{
          module: module(),
          assigns: Keyword.t()
        }

  def on_mount(:default, _params, _session, %Socket{} = socket) do
    socket =
      socket
      |> LiveView.attach_hook(:modal_hook, :handle_event, &__MODULE__.handle_event/3)
      |> LiveView.attach_hook(:modal_hook, :handle_info, &__MODULE__.handle_info/2)
      |> LiveView.assign_new(:modal, fn -> nil end)

    {:cont, socket}
  end

  def handle_event("modal:close", _params, %Socket{} = socket) do
    close_modal()
    {:halt, socket}
  end

  def handle_event(_, _params, %Socket{} = socket), do: {:cont, socket}

  def handle_info(:close_modal, %Socket{} = socket) do
    {:halt, LiveView.assign(socket, :modal, nil)}
  end

  def handle_info(_, %Socket{} = socket), do: {:cont, socket}

  @spec open_modal(Socket.t(), module(), Keyword.t()) :: Socket.t()
  def open_modal(%Socket{} = socket, module, assigns \\ []) when is_atom(module) do
    LiveView.assign(socket, :modal, %__MODULE__{module: module, assigns: assigns})
  end

  def close_modal do
    send(self(), :close_modal)
  end

  defmacro __using__(_) do
    quote do
      @view_module __MODULE__
                   |> Module.split()
                   |> Enum.slice(0..0)
                   |> List.insert_at(-1, ["Web", "View"])
                   |> List.flatten()
                   |> Module.safe_concat()

      @modal_template __ENV__.file
                      |> Path.basename(".ex")
                      |> then(&"#{&1}.html")

      alias ExshomeWeb.Live.Modal
      import Modal, only: [close_modal: 0]

      use ExshomeWeb, :live_component

      @impl Phoenix.LiveComponent
      def render(assigns), do: @view_module.render(@modal_template, assigns)
    end
  end
end
