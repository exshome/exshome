defmodule Exshome.Behaviours.DataStreamBehaviour do
  @moduledoc """
  Behaviour for exshome data streams.

  Example data Stream:
  ```
  defmodule Example.MyStream do
    @behaviour #{inspect(__MODULE__)}

    @impl #{inspect(__MODULE__)}
    def data_stream_topic({__MODULE__, id}), do: "example:my_stream:\#{id}"
    def data_stream_topic(__MODULE__), do: "example:my_stream"
  end
  ```
  """
  @type stream() :: atom() | {atom(), String.t()}

  @callback data_stream_topic(stream()) :: String.t()
end
