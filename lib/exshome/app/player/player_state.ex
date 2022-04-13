defmodule Exshome.App.Player.PlayerState do
  @moduledoc """
  A module for storing a playback state for the MPV client.
  """

  alias __MODULE__
  alias Exshome.App.Player.MpvSocket
  require Logger

  use Exshome.Dependency.GenServerDependency,
    name: "mpv_client",
    dependencies: [{MpvSocket, :socket}]

  @keys [
    :path,
    :pause,
    :volume,
    :duration,
    :time_pos,
    :metadata
  ]

  defstruct @keys

  @type t() :: %__MODULE__{
          path: String.t() | nil,
          pause: boolean() | nil,
          volume: float() | nil,
          duration: float() | nil,
          time_pos: float() | nil,
          metadata: map() | nil
        }

  defmodule Opts do
    @moduledoc """
    Initial arguments for MPV client.
    """
    defstruct [:unknown_event_handler]

    @type t() :: %__MODULE__{
            unknown_event_handler: (term() -> term()) | nil
          }
  end

  @spec on_mpv_event(map()) :: :ok
  def on_mpv_event(event) do
    cast(event)
  end

  @impl GenServerDependency
  def parse_opts(opts) do
    %Opts{
      unknown_event_handler: opts[:unknown_event_handler] || (&Logger.warn/1)
    }
  end

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{} = state) do
    if state.deps.socket == :connected do
      subscribe_to_player_state()
      update_value(state, %PlayerState{})
    else
      update_value(state, Dependency.NotReady)
    end
  end

  @impl GenServerDependency
  def handle_cast(event, state) do
    new_state = handle_event(event, state)
    {:noreply, new_state}
  end

  @spec handle_event(event :: map(), state :: DependencyState.t()) :: DependencyState.t()
  def handle_event(
        %{"event" => "property-change", "name" => name} = event,
        %DependencyState{value: %PlayerState{} = value} = state
      ) do
    new_value =
      Map.put(
        value,
        property_mapping()[name],
        event["data"]
      )

    update_value(state, new_value)
  end

  def handle_event(event, %DependencyState{} = state) do
    state.opts.unknown_event_handler.(event)
    state
  end

  @spec subscribe_to_player_state() :: term()
  defp subscribe_to_player_state do
    property_mapping()
    |> Map.keys()
    |> Enum.each(&observe_property/1)
  end

  defp observe_property(property) do
    %{} = MpvSocket.send_command(["observe_property", 1, property])
  end

  defp property_mapping do
    for key <- @keys, into: %{} do
      property_key = key |> Atom.to_string() |> String.replace(~r/_/, "-")
      {property_key, key}
    end
  end
end
