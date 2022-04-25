defmodule ExshomeWeb.App.ClockView do
  use ExshomeWeb, :view

  def format_time(%DateTime{} = data), do: Calendar.strftime(data, "%X")
  def format_date(%DateTime{} = data), do: Calendar.strftime(data, "%B %d, %Y")

  @doc """
  Calculates degree for clock hand rotation.
  value - current value for a clock hand.
  ratio - how much child clock hand progressed.
  max_value - maximum value for a clock hand.
  """
  def clock_hand_rotation(value, ratio, max_value)
      when is_integer(value) and is_integer(max_value) and is_float(ratio) do
    current = value * 360 / max_value
    next = (value + 1) * 360 / max_value
    extra = abs(next - current) * ratio
    current + extra
  end
end
