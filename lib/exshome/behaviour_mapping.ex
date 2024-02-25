defmodule Exshome.BehaviourMapping do
  @moduledoc """
  This module extracts all behaviours from code files in runtime.
  Then it computes multiple mappings from this data.
  You can use behaviours to tag modules.

  For example, you want to create event-related module.
  At first, you need to create an event-related behaviour.
  Then you can implement it in your module.
  `m:#{inspect(__MODULE__)}` allows you to get all modules that implement your behaviour.

  This module uses `m::persistent_term` to cache mappings.

  > #### Warning {: .warning}
  > This module requires `[:attributes]` chunk to be present in your BEAM files.
  > It may not work properly if you remove these chunks with `m::beam_lib` module.
  > These function names start with "strip".
  """

  alias Exshome.Behaviours.CustomMappingBehaviour

  @module_behaviours_key {__MODULE__, :module_behaviours}
  @behaviour_implementations_key {__MODULE__, :behaviour_implementations}
  @custom_mapping_key {__MODULE__, :custom_mapping}
  @mapping_not_found :not_found

  @type mapping_t() :: %{module() => MapSet.t(module())}

  @type custom_mapping_t() :: %{module() => term()}

  @doc """
  Recomputes all mappings and updates caches.

  This operation is useful during development.
  You can update your behaviour and run this function to recompute mappings without restarting the application.
  You don't need to run it on every change.

  The more code you have, the more time it will take to recompute mappings.
  """
  @spec recompute_mapping() :: %{
          module_behaviours: mapping_t(),
          behaviour_implementations: mapping_t(),
          custom_mapping: custom_mapping_t()
        }
  def recompute_mapping do
    computed_module_behaviours = compute_module_behaviours()

    computed_behaviour_implementations =
      for {module, behaviours} <- computed_module_behaviours,
          behaviour <- behaviours,
          reduce: %{} do
        mapping ->
          Map.update(
            mapping,
            behaviour,
            MapSet.new([module]),
            &MapSet.put(&1, module)
          )
      end

    computed_custom_mapping = compute_custom_mapping(computed_behaviour_implementations)

    :persistent_term.put(@module_behaviours_key, computed_module_behaviours)
    :persistent_term.put(@behaviour_implementations_key, computed_behaviour_implementations)
    :persistent_term.put(@custom_mapping_key, computed_custom_mapping)

    %{
      module_behaviours: computed_module_behaviours,
      behaviour_implementations: computed_behaviour_implementations,
      custom_mapping: computed_custom_mapping
    }
  end

  @doc """
  Returns `%{module => MapSet.new([module_behaviours])}` mapping.
  """
  @spec module_behaviours() :: mapping_t()
  def module_behaviours do
    case :persistent_term.get(@module_behaviours_key, @mapping_not_found) do
      @mapping_not_found ->
        %{module_behaviours: mapping} = recompute_mapping()
        mapping

      result ->
        result
    end
  end

  @doc """
  Returns a set of behaviours a module implements.
  """
  @spec module_behaviours(module()) :: MapSet.t(module())
  def module_behaviours(module), do: Map.get(module_behaviours(), module, MapSet.new())

  @doc """
  Returns `%{behaviour_module => MapSet.new([implementations])}` mapping.
  """
  @spec behaviour_implementations() :: mapping_t()
  def behaviour_implementations do
    case :persistent_term.get(@behaviour_implementations_key, @mapping_not_found) do
      @mapping_not_found ->
        %{behaviour_implementations: mapping} = recompute_mapping()
        mapping

      result ->
        result
    end
  end

  @doc """
  Returns a set of moudles, that implement specific behaviour.
  """
  @spec behaviour_implementations(module()) :: MapSet.t(module())
  def behaviour_implementations(module),
    do: Map.get(behaviour_implementations(), module, MapSet.new())

  @doc """
  Returns `%{custom_mapping_module => term()}`, where `term()` can be anything that you need.

  Custom mapping is computed after other mappings are built.
  It is cached too.
  You can register custom mapping by implementing a `m:Exshome.Behaviours.CustomMappingBehaviour`.
  """
  @spec custom_mapping() :: custom_mapping_t()
  def custom_mapping do
    case :persistent_term.get(@custom_mapping_key, @mapping_not_found) do
      @mapping_not_found ->
        %{custom_mapping: mapping} = recompute_mapping()
        mapping

      result ->
        result
    end
  end

  @doc """
  Returns a value for custom mapping.
  """
  @spec custom_mapping!(module()) :: term()
  def custom_mapping!(module), do: Map.fetch!(custom_mapping(), module)

  @spec compute_module_behaviours() :: mapping_t()
  defp compute_module_behaviours do
    compiled_mapping =
      :code.all_available()
      |> Enum.map(&elem(&1, 1))
      |> Task.async_stream(:beam_lib, :chunks, [[:attributes]], ordered: false)
      |> Enum.reduce(%{}, fn
        {:ok, {:ok, {module, [attributes: attrs]}}}, acc ->
          case Keyword.get_values(attrs, :behaviour) do
            [] ->
              acc

            behaviours ->
              behaviours = behaviours |> List.flatten() |> MapSet.new()
              Map.put(acc, module, behaviours)
          end

        _, acc ->
          acc
      end)

    case Code.ensure_compiled(:cover) do
      {:module, compiled_module} ->
        for module <- compiled_module.modules(), into: compiled_mapping do
          behaviours =
            module.__info__(:attributes)
            |> Keyword.get_values(:behaviour)
            |> List.flatten()
            |> MapSet.new()

          {module, behaviours}
        end

      _ ->
        compiled_mapping
    end
  end

  @spec compute_custom_mapping(mapping_t()) :: custom_mapping_t()
  defp compute_custom_mapping(mapping) do
    for module <- Map.get(mapping, CustomMappingBehaviour, []), into: %{} do
      {module, module.compute_custom_mapping(mapping)}
    end
  end
end
