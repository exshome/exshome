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
end
