defmodule ExshomeAutomation do
  @moduledoc """
  Application related to automation.
  """

  alias ExshomeAutomation.Web.Live

  use ExshomeWeb.App,
    pages: [
      {Live.Automations,
       [
         {".*", Live.AutomationEditor}
       ]},
      Live.Variables
    ],
    prefix: "automation",
    preview: Live.Preview

  use Exshome.Behaviours.AppBehaviour

  @impl AppBehaviour
  def app_settings,
    do: %AppBehaviour{
      pages: [Live.Automations, Live.AutomationEditor, Live.Variables],
      prefix: "automation",
      preview: Live.Preview
    }
end
