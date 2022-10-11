defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  alias ExshomeAutomation.Services.WorkflowRegistry

  use ExshomeWeb.Live.AppPage,
    dependencies: [{WorkflowRegistry, :workflows}],
    icon: "🤖️"
end
