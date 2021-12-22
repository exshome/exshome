defmodule ExshomeTest.TestMpvServer do
  @moduledoc """
  Test MPV server. You can use it to emulate an MPV server.
  """
  use GenServer

  defmodule State do
    @moduledoc """
    A structure to represent internal state of test MPV server.
    """
    defstruct [
      :socket_path,
      :server,
      :connection,
      :response_fn,
      observed_properties: MapSet.new(),
      received_messages: []
    ]

    @type t() :: %__MODULE__{
            connection: :gen_tcp.socket() | nil,
            received_messages: [term()],
            server: :gen_tcp.socket() | nil,
            socket_path: String.t() | nil,
            observed_properties: MapSet.t(),
            response_fn: ExshomeTest.TestMpvServer.response_fn() | nil
          }
  end

  defmodule Arguments do
    @moduledoc """
    Arguments to start a test MPV server.
    """
    @enforce_keys [:socket_path]
    defstruct [:socket_path]

    @type t() :: %__MODULE__{
            socket_path: String.t()
          }
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

  @impl GenServer
  def init(%Arguments{socket_path: socket_path}) do
    File.rm(socket_path)

    {:ok, server} =
      :gen_tcp.listen(0, [
        {:ip, {:local, socket_path}},
        :binary,
        {:packet, :line},
        reuseaddr: true
      ])

    state = %State{socket_path: socket_path, server: server}
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
        %{"command" => ["observe_property", 1, property_name]},
        %State{} = state
      ) do
    new_state = %State{
      state
      | observed_properties: MapSet.put(state.observed_properties, property_name)
    }

    send_data(new_state, %{request_id: request_id, error: "success"})
    update_property(state, property_name, nil)
    {:noreply, new_state}
  end

  def default_response_handler(
        request_id,
        %{
          "command" => ["loadfile", path]
        },
        %State{} = state
      ) do
    update_property(state, "path", path)
    send_data(state, %{request_id: request_id, error: "success"})
    {:noreply, state}
  end

  def default_response_handler(
        request_id,
        %{
          "command" => ["set_property", property, value]
        },
        %State{} = state
      ) do
    update_property(state, property, value)
    send_data(state, %{request_id: request_id, error: "success"})
    {:noreply, state}
  end

  def default_response_handler(request_id, _request_data, %State{} = state) do
    send_data(state, %{test: 123, request_id: request_id, error: "success"})
    {:noreply, state}
  end

  defp update_property(%State{} = state, property_name, value) do
    if MapSet.member?(state.observed_properties, property_name) do
      send_client_event(state, %{event: "property-change", name: property_name, data: value})
    end
  end

  defp send_client_event(%State{} = state, event) do
    send_data(state, event)
  end

  defp send_data(%State{} = state, data) do
    json_data = Jason.encode!(data)
    :gen_tcp.send(state.connection, "#{json_data}\n")
  end
end
