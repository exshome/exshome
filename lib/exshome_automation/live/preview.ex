defmodule ExshomeAutomation.Live.Preview do
  @moduledoc """
  Automation preview widget.
  """
  alias ExshomeAutomation.Services.AutomationStatus

  use ExshomeWeb.Live.AppPage,
    dependencies: [{AutomationStatus, :status}]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <section class="h-full w-full flex flex-col items-center justify-center">
        <table class="text-xs sm:text-sm md:text-md lg:text-2xl text-center">
          <thead>
            <td></td>
            <td><.icon name="hero-check-circle-solid" class="text-green-700" /></td>
            <td><.icon name="hero-exclamation-triangle-solid" class="text-orange-400" /></td>
          </thead>
          <tr>
            <td><span class="hero-variable-mini" /></td>
            <td type="ready_variables">{@deps.status.ready_variables}</td>
            <td type="not_ready_variables">{@deps.status.not_ready_variables}</td>
          </tr>
          <tr>
            <td><span class="hero-command-line-mini" /></td>
            <td type="ready_workflows">{@deps.status.ready_workflows}</td>
            <td type="not_ready_workflows">{@deps.status.not_ready_workflows}</td>
          </tr>
        </table>
        <p class="text-xl md:text-2xl lg:text-3xl">Automation</p>
      </section>
    </.missing_deps_placeholder>
    """
  end
end
