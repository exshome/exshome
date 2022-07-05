defmodule ExshomeAutomation.Web.Live.Preview do
  @moduledoc """
  Automation preview widget.
  """
  alias ExshomeAutomation.Services.AutomationStatus

  use ExshomeWeb.Live.AppPage,
    dependencies: [{AutomationStatus, :status}]
end
