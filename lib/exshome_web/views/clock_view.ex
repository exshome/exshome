defmodule ExshomeWeb.ClockView do
  use ExshomeWeb, :view

  def format_time(%DateTime{} = data), do: Calendar.strftime(data, "%X")
  def format_date(%DateTime{} = data), do: Calendar.strftime(data, "%B %d, %Y")
end
