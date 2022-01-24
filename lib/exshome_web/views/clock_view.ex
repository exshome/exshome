defmodule ExshomeWeb.ClockView do
  use ExshomeWeb, :view

  def format_time(%DateTime{} = data), do: Calendar.strftime(data, "%X")
  def format_date(%DateTime{} = data), do: Calendar.strftime(data, "%B %d, %Y")

  def clock_hand_rotation(value) when is_integer(value), do: value * 360 / 60
end
