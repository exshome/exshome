defmodule Exshome.App.Clock.UtcTime do
  @moduledoc """
  UTC time dependency.
  """
  use Exshome.Dependency.GenServerDependency, name: "utc_time"

  defmodule Opts do
    @moduledoc """
    UtcTimeService options.
    """

    defstruct [:refresh_interval, :precision]

    @type t() :: %__MODULE__{
            refresh_interval: non_neg_integer(),
            precision: :microsecond | :millisecond | :second
          }
  end

  @impl GenServerDependency
  def on_init(state) do
    schedule_next_tick(state)
  end

  @impl GenServerDependency
  def parse_opts(opts) do
    %Opts{
      refresh_interval: opts[:refresh_interval] || 200,
      precision: opts[:precision] || :second
    }
  end

  @impl GenServerDependency
  def handle_info(:tick, state) do
    new_state = schedule_next_tick(state)
    {:noreply, new_state}
  end

  def schedule_next_tick(%DependencyState{opts: %Opts{} = opts} = state) do
    update_interval = opts.refresh_interval
    Process.send_after(self(), :tick, update_interval)
    update_value(state, prepare_value(opts))
  end

  def prepare_value(%Opts{precision: precision}) do
    DateTime.truncate(DateTime.utc_now(), precision)
  end
end
