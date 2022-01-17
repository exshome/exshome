defmodule Exshome.Service.ClockService do
  @moduledoc """
  Application clock server.
  """

  defmodule Opts do
    @moduledoc """
    ClockService options.
    """

    defstruct [:refresh_interval, :precision]

    @type t() :: %__MODULE__{
            refresh_interval: non_neg_integer(),
            precision: :microsecond | :millisecond | :second
          }
  end

  alias Exshome.Service.State
  use Exshome.Service, pubsub_key: "clock"

  def on_init(state) do
    schedule_next_tick(state)
  end

  def parse_opts(opts) do
    %Opts{
      refresh_interval: opts[:refresh_interval] || 200,
      precision: opts[:precision] || :second
    }
  end

  def handle_info(:tick, state) do
    new_state = schedule_next_tick(state)
    {:noreply, new_state}
  end

  def schedule_next_tick(%State{opts: %Opts{} = opts} = state) do
    update_interval = opts.refresh_interval
    Process.send_after(self(), :tick, update_interval)
    update_value(state, prepare_value(opts))
  end

  def prepare_value(%Opts{precision: precision}) do
    DateTime.truncate(DateTime.utc_now(), precision)
  end
end