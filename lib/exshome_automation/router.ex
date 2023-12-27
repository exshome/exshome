defmodule ExshomeAutomation.Router do
  @moduledoc """
  Routes for automation application.
  """

  use Exshome.Behaviours.RouterBehaviour, key: "automation"

  alias ExshomeAutomation.Web.Live

  scope "/app/automation" do
    live "/automations", Live.Automations
    live "/automations/:id", Live.Automations
    live "/variables", Live.Variables
  end
end
