defmodule ExshomeWeb.ServicePage.ClockView do
  use ExshomeWeb, :view

  def format_time(%DateTime{} = data), do: Calendar.strftime(data, "%X")
  def format_date(%DateTime{} = data), do: Calendar.strftime(data, "%B %d, %Y")

  def clock_hand_rotation(value, max_value)
      when is_integer(value) and is_integer(max_value),
      do: value * 360 / max_value
end
