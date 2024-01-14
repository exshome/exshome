defmodule ExshomeClock.Live.Preview do
  @moduledoc """
  Clock preview widget.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.Services.LocalTime, :time}]

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
