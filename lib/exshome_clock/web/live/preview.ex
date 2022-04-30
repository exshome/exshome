defmodule ExshomeClock.Web.Live.Preview do
  @moduledoc """
  Clock preview widget.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.Services.LocalTime, :time}]
end
