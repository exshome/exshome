defmodule ExshomeTest.TestMpvServer do
  @moduledoc """
  Test MPV server. You can use it to emulate an MPV server.
  """
  use GenServer
  alias Exshome.App.Player.MpvSocket

  defmodule State do
    @moduledoc """
    A structure to represent internal state of test MPV server.
    """
    defstruct [
      :server,
      :connection,
      :response_fn,
      observed_properties: MapSet.new(),
      received_messages: [],
      playlist: []
    ]

    @type t() :: %__MODULE__{
            connection: :gen_tcp.socket() | nil,
            received_messages: [term()],
            server: :gen_tcp.socket() | nil,
            observed_properties: MapSet.t(),
            response_fn: ExshomeTest.TestMpvServer.response_fn() | nil,
            playlist: [String.t()]
          }
  end

  defmodule Arguments do
    @moduledoc """
    Arguments to start a test MPV server.
    """
    @enforce_keys [:init_fn]
    defstruct [:init_fn]

    @type t() :: %__MODULE__{init_fn: (() -> any())}
  end

  @type response_fn() :: (request_id :: String.t(), data :: map() -> map())

  @spec start_link(Arguments.t()) :: GenServer.on_start()
  def start_link(%Arguments{} = init_arguments) do
    GenServer.start_link(__MODULE__, init_arguments)
  end

  @spec set_response_fn(server :: pid(), response_fn :: response_fn()) :: term()
  def set_response_fn(server, response_fn) do
    GenServer.call(server, {:set_response_fn, response_fn})
  end

  @spec received_messages(pid()) :: [%{}]
  def received_messages(server) do
    GenServer.call(server, :messages)
  end

  @spec send_event(server :: pid(), event :: %{}) :: term()
  def send_event(server, event) do
    GenServer.call(server, {:event, event})
  end

  @spec playlist(server :: pid()) :: list(String.t())
  def playlist(server) do
    GenServer.call(server, :get_playlist)
  end

  @impl GenServer
  def init(%Arguments{init_fn: init_fn}) do
    init_fn.()
    socket_path = MpvSocket.socket_path()
    File.rm(socket_path)

    {:ok, server} =
      :gen_tcp.listen(0, [
        {:ip, {:local, socket_path}},
        :binary,
        {:packet, :line},
        reuseaddr: true
      ])

    state = %State{server: server}
    {:ok, state, {:continue, :accept_connection}}
  end

  @impl GenServer
  def handle_continue(:accept_connection, %State{} = state) do
    {:ok, connection} = :gen_tcp.accept(state.server)
    new_state = %State{state | connection: connection}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:tcp, port, message}, %State{} = state) when port == state.connection do
    decoded = Jason.decode!(message)
    new_state = Map.update!(state, :received_messages, &[decoded | &1])

    request_id = decoded["request_id"]

    if new_state.response_fn do
      response = state.response_fn.(request_id, decoded)
      send_data(state, response)
      {:noreply, new_state}
    else
      default_response_handler(request_id, decoded, new_state)
    end
  end

  @impl GenServer
  def handle_call(:messages, _from, %State{} = state) do
    {:reply, state.received_messages, state}
  end

  @impl GenServer
  def handle_call(:get_playlist, _from, %State{} = state) do
    {:reply, state.playlist, state}
  end

  @impl GenServer
  def handle_call({:event, event}, _from, %State{} = state) do
    send_client_event(state, event)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:set_response_fn, response_fn}, _from, %State{} = state) do
    new_state = %State{state | response_fn: response_fn}
    {:reply, :ok, new_state}
  end

  @spec default_response_handler(
          request_id :: String.t(),
          request_data :: map(),
          state :: State.t()
        ) :: {:noreply, State.t()}
  def default_response_handler(
        request_id,
        %{"command" => [command_name | args]},
        %State{} = state
      ) do
    new_state = handle_command(command_name, args, state)
    send_data(new_state, %{request_id: request_id, error: "success"})
    {:noreply, new_state}
  end

  def default_response_handler(request_id, _request_data, %State{} = state) do
    send_data(state, %{test: 123, request_id: request_id, error: "success"})
    {:noreply, state}
  end

  @spec handle_command(command_name :: String.t(), args :: list(), state :: State.t()) ::
          State.t()
  defp handle_command("observe_property", [_subscription_id, property_name], %State{} = state) do
    %State{
      state
      | observed_properties: MapSet.put(state.observed_properties, property_name)
    }
    |> update_property(property_name, nil)
  end

  defp handle_command("loadfile", [path], %State{} = state) do
    %State{
      state
      | playlist: [path | state.playlist]
    }
    |> update_property("path", path)
  end

  defp handle_command("playlist-clear", [], %State{} = state) do
    %State{state | playlist: []}
  end

  defp handle_command("set_property", [property_name, value], %State{} = state) do
    update_property(state, property_name, value)
  end

  defp handle_command("seek", [value, "absolute"], %State{} = state) do
    update_property(state, "time-pos", value)
  end

  @spec update_property(state :: State.t(), property_name :: String.t(), value :: term()) ::
          State.t()
  defp update_property(%State{} = state, property_name, value) do
    if MapSet.member?(state.observed_properties, property_name) do
      send_client_event(state, %{event: "property-change", name: property_name, data: value})
    end

    state
  end

  defp send_client_event(%State{} = state, event) do
    send_data(state, event)
  end

  defp send_data(%State{} = state, data) do
    json_data = Jason.encode!(data)
    :gen_tcp.send(state.connection, "#{json_data}\n")
  end
end
