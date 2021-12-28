defmodule ExshomeWeb.Live.ClockTest do
  use ExshomeWeb.ConnCase, async: true
  alias ExshomeWeb.Live.Clock.Index
  import Phoenix.LiveViewTest

  @months [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ]

  test "renders a current time", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.clock_index_path(conn, :index))

    assert datetime_from_view(view) <= DateTime.utc_now()
  end

  test "updates a time", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.clock_index_path(conn, :index))
    initial_datetime = datetime_from_view(view)
    assert initial_datetime <= DateTime.utc_now()
    update_timer(view)
    updated_datetime = datetime_from_view(view)
    assert updated_datetime <= DateTime.utc_now()
    assert initial_datetime <= updated_datetime
  end

  defp datetime_from_view(view) do
    time = time_from_view(view)
    date = date_from_view(view)
    DateTime.new!(date, time)
  end

  defp time_from_view(view) do
    time =
      extract_values(
        view,
        "#clock_time",
        ~r/^(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})$/
      )
      |> values_to_int()

    Time.new!(time["hour"], time["minute"], time["second"])
  end

  defp date_from_view(view) do
    date =
      extract_values(
        view,
        "#clock_date",
        ~r/^(?<month>\w+) (?<day>\d{2}), (?<year>\d{4})$/
      )
      |> convert_month()
      |> values_to_int()

    Date.new!(date["year"], date["month"], date["day"])
  end

  defp extract_values(view, selector, regex) do
    target_element = element(view, selector)
    assert has_element?(target_element)
    target_text = target_element |> render() |> Floki.text()
    assert Regex.named_captures(regex, target_text)
  end

  defp values_to_int(%{} = data) do
    for {key, value} <- data, into: %{}, do: {key, String.to_integer(value)}
  end

  defp convert_month(%{"month" => month} = data) do
    month_index = Enum.find_index(@months, fn m -> m == month end) + 1
    Map.put(data, "month", Integer.to_string(month_index))
  end

  defp update_timer(%Phoenix.LiveViewTest.View{pid: pid}) do
    Index.schedule_tick(pid, 0)
  end
end
