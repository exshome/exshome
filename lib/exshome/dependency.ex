defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Dependency.NotReady

  @type dependency() :: atom()
  @type get_value_result :: term() | NotReady

  @callback get_value() :: get_value_result()

  @spec get_value(dependency()) :: get_value_result()
  def get_value(dependency) do
    raise_if_not_dependency!(dependency)
    dependency.get_value()
  end

  @spec subscribe(dependency()) :: get_value_result()
  def subscribe(dependency) do
    result = get_value(dependency)
    :ok = Exshome.PubSub.subscribe(dependency.name())

    case result do
      NotReady -> get_value(dependency)
      data -> data
    end
  end

  @spec unsubscribe(dependency()) :: :ok
  def unsubscribe(dependency) do
    raise_if_not_dependency!(dependency)
    Exshome.PubSub.unsubscribe(dependency.name())
  end

  defp raise_if_not_dependency!(module) do
    if !module_is_dependency?(module) do
      raise "#{inspect(module)} is not a dependency!"
    end
  end

  @spec module_is_dependency?(module()) :: boolean()
  defp module_is_dependency?(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    module_has_correct_behaviour && module_has_name
  end

  @spec dependency_message?(term()) :: boolean()
  def dependency_message?({module, _value}), do: module_is_dependency?(module)
  def dependency_message?(_), do: false

  def broadcast_value(dependency, value) do
    raise_if_not_dependency!(dependency)
    Exshome.PubSub.broadcast(dependency.name(), {dependency, value})
  end

  defmacro __using__(_) do
    quote do
      alias Exshome.Dependency
      @behaviour Dependency
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Dependency)
    end
  end
end
