defmodule ExshomeAutomation do
  @moduledoc """
  Application related to automation.
  """

  alias ExshomeAutomation.Web.Live

  use Exshome.Behaviours.AppBehaviour,
    pages: [
      {Live.Automations,
       [
         {".*", Live.AutomationEditor}
       ]},
      {Live.Variables, []}
    ],
    prefix: "automation",
    preview: Live.Preview,
    template_root: "./exshome_automation/web/templates"

  @impl AppBehaviour
  def can_start?, do: true
end
