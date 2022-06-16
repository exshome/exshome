defmodule ExshomeWeb.Components do
  @moduledoc """
  Generic application components.
  """

  alias Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  def button(assigns) do
    extra = assigns_to_attributes(assigns, [:class])
    assigns = LiveView.assign(assigns, :extra, extra)

    ~H"""
    <button
      class="p-2 m-2 rounded-xl
             bg-gray-200 dark:bg-gray-600 hover:bg-gray-300 dark:hover:bg-gray-500
             shadow-md shadow-gray-600 dark:shadow-gray-700"
      {@extra}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
