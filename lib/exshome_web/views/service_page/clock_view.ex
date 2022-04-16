defmodule ExshomeWeb.ServicePage.ClockView do
  use ExshomeWeb, :view

  def format_time(%DateTime{} = data), do: Calendar.strftime(data, "%X")
  def format_date(%DateTime{} = data), do: Calendar.strftime(data, "%B %d, %Y")

  def clock_hand_rotation(value, child_value, max_value)
      when is_integer(value) and is_integer(max_value) and is_integer(child_value) do
    current = value * 360 / max_value
    next = (value + 1) * 360 / max_value
    extra = child_value * abs(next - current) / 60
    current + extra
  end
end
