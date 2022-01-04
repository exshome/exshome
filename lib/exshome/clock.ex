defmodule Exshome.Clock do
  @moduledoc """
  Application clock server.
  """

  use Exshome.PubSub, pubsub_key: "clock", fields: [time: DateTime.t()]

  @update_interval Application.compile_env(:exshome, :clock_refresh_interval, 200)

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, [])
  end

  @impl GenServer
  def init(%{}) do
    schedule_next_tick()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    schedule_next_tick()
    {:noreply, state}
  end

  def schedule_next_tick do
    broadcast(get_state())
    Process.send_after(self(), :tick, @update_interval)
  end

  def get_state, do: %__MODULE__{time: DateTime.utc_now()}
end
