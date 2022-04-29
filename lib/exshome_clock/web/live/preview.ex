defmodule ExshomeClock.Web.Live.Preview do
  @moduledoc """
  Clock preview widget.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.LocalTime, :time}]
end
