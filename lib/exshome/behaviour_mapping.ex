defmodule Exshome.BehaviourMapping do
  @moduledoc """
  Computes mapping for all behaviours in application.
  """

  @behaviour_mapping_key {__MODULE__, :behaviour_mapping}
  @custom_mapping_key {__MODULE__, :custom_mapping}
  @mapping_not_found :not_found

  @type behaviour_mapping_t() :: %{module() => MapSet.t(module())}
  @type custom_mapping_t() :: %{module() => term()}

  alias Exshome.Behaviours.CustomMappingBehaviour

  @spec compute_custom_mapping(behaviour_mapping_t()) :: custom_mapping_t()
  defp compute_custom_mapping(mapping) do
    for module <- Map.get(mapping, CustomMappingBehaviour, []), into: %{} do
      {module, module.compute_custom_mapping(mapping)}
    end
  end

  defp list_module_behaviours do
    compiled_mapping =
      :code.all_available()
      |> Enum.map(&elem(&1, 1))
      |> Task.async_stream(:beam_lib, :chunks, [[:attributes]], ordered: false)
      |> Enum.reduce(%{}, fn
        {:ok, {:ok, {module, [attributes: attrs]}}}, acc ->
          case Keyword.get_values(attrs, :behaviour) do
            [] -> acc
            behaviours -> Map.put(acc, module, List.flatten(behaviours))
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

          {module, behaviours}
        end

      _ ->
        compiled_mapping
    end
  end

  @spec recompute_mapping() :: {behaviour_mapping_t(), custom_mapping_t()}
  def recompute_mapping do
    computed_behaviour_mapping =
      for {module, behaviours} <- list_module_behaviours(),
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

    computed_custom_mapping = compute_custom_mapping(computed_behaviour_mapping)
    :persistent_term.put(@behaviour_mapping_key, computed_behaviour_mapping)
    :persistent_term.put(@custom_mapping_key, computed_custom_mapping)
    {computed_behaviour_mapping, computed_custom_mapping}
  end

  @spec behaviour_mapping() :: behaviour_mapping_t()
  def behaviour_mapping do
    case :persistent_term.get(@behaviour_mapping_key, @mapping_not_found) do
      @mapping_not_found ->
        {mapping, _} = recompute_mapping()
        mapping

      result ->
        result
    end
  end

  @spec behaviour_mapping!(module()) :: MapSet.t(module())
  def behaviour_mapping!(module) do
    Map.fetch!(behaviour_mapping(), module)
  end

  @spec custom_mapping() :: custom_mapping_t()
  def custom_mapping do
    case :persistent_term.get(@custom_mapping_key, @mapping_not_found) do
      @mapping_not_found ->
        {_, mapping} = recompute_mapping()
        mapping

      result ->
        result
    end
  end

  @spec custom_mapping!(module()) :: term()
  def custom_mapping!(module) do
    Map.fetch!(custom_mapping(), module)
  end
end
