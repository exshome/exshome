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
    {:halt, close_modal(socket)}
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

  @spec close_modal(Socket.t()) :: Socket.t()
  def close_modal(%Socket{} = socket) do
    socket
    |> modal_view_pid()
    |> send(:close_modal)

    socket
  end

  @spec modal_view_pid(Socket.t()) :: pid()
  defp modal_view_pid(%Socket{parent_pid: nil}), do: self()
  defp modal_view_pid(%Socket{parent_pid: pid}) when is_pid(pid), do: pid
end
