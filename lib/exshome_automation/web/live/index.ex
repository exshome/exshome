defmodule ExshomeAutomation.Web.Live.Index do
  @moduledoc """
  Main automation page.
  """
  alias ExshomeAutomation.Services.VariableRegistry

  use ExshomeWeb.Live.AppPage,
    dependencies: [{VariableRegistry, :variables}],
    icon: ""
end
