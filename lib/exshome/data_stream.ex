defmodule Exshome.DataStream do
  @moduledoc """
  Contains all DataStream-related features.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.NotReady

  @type stream() :: atom() | {atom(), String.t()}
  @type value() :: [term()] | NotReady
  @type stream_diff() :: [Operation.t()]
  @callback get_value(stream()) :: value()

  @spec get_value(stream()) :: value()
  def get_value(stream) do
    raise_if_not_stream_module!(stream)
    stream_module(stream).get_value(stream)
  end

  @spec subscribe(stream()) :: value()
  def subscribe(stream) do
    result = get_value(stream)

    :ok =
      stream
      |> pub_sub_topic()
      |> Exshome.PubSub.subscribe()

    case result do
      NotReady -> get_value(stream)
      data -> data
    end
  end

  @spec unsubscribe(stream()) :: :ok
  def unsubscribe(stream) do
    :ok =
      stream
      |> pub_sub_topic()
      |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast(stream(), stream_diff()) :: :ok
  def broadcast(stream, diff) do
    :ok =
      stream
      |> pub_sub_topic()
      |> Exshome.PubSub.broadcast({__MODULE__, {stream, diff}})
  end

  @spec pub_sub_topic(stream()) :: String.t()
  defp pub_sub_topic({stream_module, id}) when is_atom(stream_module) and is_binary(id) do
    Enum.join([pub_sub_topic(stream_module), id], ":")
  end

  defp pub_sub_topic(stream_module) when is_atom(stream_module) do
    raise_if_not_stream_module!(stream_module)
    stream_module.name()
  end

  @spec stream_module(stream()) :: module()
  def stream_module({module, id}) when is_binary(id), do: stream_module(module)

  def stream_module(module) when is_atom(module) do
    raise_if_not_stream_module!(module)
    module
  end

  defp raise_if_not_stream_module!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    correct_module = module_has_correct_behaviour && module_has_name

    if !correct_module do
      raise "#{inspect(module)} is not a #{__MODULE__}!"
    end
  end

  defmacro __using__(name: name) do
    quote do
      alias Exshome.DataStream
      use Exshome.Named, "event:#{unquote(name)}"
      @behaviour DataStream
      add_tag(DataStream)
    end
  end
end
