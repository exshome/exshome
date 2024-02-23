defmodule Exshome.Behaviours.DataStreamBehaviour do
  @moduledoc """
  Behaviour for exshome data streams.

  Example data Stream:
  ```
  defmodule Example.MyStream do
    @behaviour #{inspect(__MODULE__)}

    @impl #{inspect(__MODULE__)}
    def data_stream_topic, do: "example:my_stream"
  end
  ```
  """
  @callback data_stream_topic() :: String.t()
end
