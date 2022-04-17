defmodule Exshome.Event do
  @moduledoc """
  Contains all event-related features.
  """
  @type event_module() :: atom()
  @type event_message() :: struct()

  @spec subscribe(event_module()) :: :ok
  def subscribe(event_module) do
    :ok =
      event_module
      |> pub_sub_topic!()
      |> Exshome.PubSub.subscribe()
  end

  @spec unsubscribe(event_module()) :: :ok
  def unsubscribe(event_module) do
    :ok =
      event_module
      |> pub_sub_topic!()
      |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast(struct()) :: :ok
  def broadcast(%event_module{} = event) do
    :ok =
      event_module
      |> pub_sub_topic!()
      |> Exshome.PubSub.broadcast({__MODULE__, event})
  end

  @spec pub_sub_topic!(event_module()) :: String.t()
  defp pub_sub_topic!(event_module) do
    raise_if_not_event_module!(event_module)
    event_module.name()
  end

  defp raise_if_not_event_module!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    module_is_struct = function_exported?(module, :__struct__, 1)
    correct_module = module_has_correct_behaviour && module_has_name && module_is_struct

    if !correct_module do
      raise "#{inspect(module)} does not emit events!"
    end
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: :ok
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    module_is_struct = function_exported?(module, :__struct__, 1)

    if !module_is_struct do
      raise """
      #{inspect(module)} should be a struct!
      Please, use `defstruct` to use it as event.
      """
    end

    :ok
  end

  defmacro __using__(name: name) do
    quote do
      alias Exshome.Event
      @after_compile {Event, :validate_module!}
      use Exshome.Named, "event:#{unquote(name)}"
      add_tag(Event)
    end
  end
end
