defmodule ExshomeWeb.Live.Modal do
  @moduledoc """
  Adds modal support for every live page.
  """
  alias Phoenix.LiveView
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  defstruct [:module, :assigns]

  @type t() :: %__MODULE__{
          module: module(),
          assigns: Keyword.t()
        }

  @type js_t() :: %JS{ops: list()}

  def on_mount(:default, _params, _session, %Socket{} = socket) do
    socket =
      socket
      |> LiveView.attach_hook(:modal_hook, :handle_event, &__MODULE__.handle_event/3)
      |> LiveView.attach_hook(:modal_hook, :handle_info, &__MODULE__.handle_info/2)
      |> LiveView.assign_new(:modal, fn -> nil end)

    {:cont, socket}
  end

  def handle_event("modal:close", _params, %Socket{} = socket) do
    {:halt, close_modal(socket)}
  end

  def handle_event(_, _params, %Socket{} = socket), do: {:cont, socket}

  def handle_info(:close_modal, %Socket{} = socket) do
    {:halt, LiveView.assign(socket, :modal, nil)}
  end

  def handle_info(_, %Socket{} = socket), do: {:cont, socket}

  @spec open_modal(Socket.t(), module(), Keyword.t()) :: Socket.t()
  def open_modal(%Socket{} = socket, module, assigns \\ []) when is_atom(module) do
    socket
    |> LiveView.assign(:modal, %__MODULE__{module: module, assigns: assigns})
    |> send_js(opening_transition())
  end

  @spec close_modal(Socket.t()) :: Socket.t()
  def close_modal(%Socket{} = socket) do
    socket
    |> modal_view_pid()
    |> send(:close_modal)

    send_js(socket, closing_transition())
  end

  @spec send_js(Socket.t(), js_t()) :: Socket.t()
  def send_js(%Socket{} = socket, %JS{ops: ops}) do
    LiveView.push_event(socket, "js-event", %{data: Jason.encode!(ops)})
  end

  @spec modal_view_pid(Socket.t()) :: pid()
  defp modal_view_pid(%Socket{parent_pid: nil}), do: self()
  defp modal_view_pid(%Socket{parent_pid: pid}) when is_pid(pid), do: pid

  defp opening_transition do
    %JS{}
    |> JS.show(to: "#modal", transition: "fade-in")
    |> JS.show(to: "#modal-content", transition: "fade-in-scale")
  end

  defp closing_transition do
    %JS{}
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.show(to: "#modal-content", transition: "fade-out-scale")
  end
end
