defmodule ExshomeAutomation do
  @moduledoc """
  Application related to automation.
  """

  alias ExshomeAutomation.Web.Live

  use ExshomeWeb.App,
    pages: [Live.Variables, Live.Automations, Live.AutomationEditor],
    prefix: "automation",
    preview: Live.Preview
end
