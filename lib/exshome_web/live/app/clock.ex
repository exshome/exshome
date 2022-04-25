defmodule ExshomeWeb.Live.App.Clock do
  @moduledoc """
  Live clock applicaton.
  """

  defmodule Index do
    @moduledoc """
    Main clock page.
    """

    use ExshomeWeb.Live.AppPage,
      dependencies: [{Exshome.App.Clock.LocalTime, :time}],
      icon: "⏰"
  end

  defmodule Preview do
    @moduledoc """
    Clock preview widget.
    """

    use ExshomeWeb.Live.AppPage,
      dependencies: [{Exshome.App.Clock.LocalTime, :time}]
  end

  defmodule Settings do
    @moduledoc """
    Clock settings page.
    """

    use ExshomeWeb.Live.AppPage,
      dependencies: [{Exshome.App.Clock.ClockSettings, :settings}],
      icon: "⚙"
  end

  use ExshomeWeb.Live.App,
    pages: [Index, Settings],
    prefix: :clock,
    preview: Preview,
    view_module: ExshomeWeb.App.ClockView
end
