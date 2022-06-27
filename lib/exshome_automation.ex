defmodule ExshomeAutomation do
  @moduledoc """
  Application related to automation.
  """

  alias ExshomeAutomation.Web.Live

  use Exshome.App,
    pages: [Live.Index],
    prefix: :automation,
    preview: Live.Preview
end
