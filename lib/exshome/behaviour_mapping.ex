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

  @spec recompute_mapping() :: {behaviour_mapping_t(), custom_mapping_t()}
  def recompute_mapping do
    behaviours_by_module =
      for {_, beam_file, _} <- :code.all_available(), reduce: %{} do
        mapping ->
          case :beam_lib.chunks(beam_file, [:attributes]) do
            {:ok, {module, [attributes: attrs]}} ->
              behaviours =
                attrs
                |> Keyword.get_values(:behaviour)
                |> List.flatten()

              Map.put(mapping, module, behaviours)

            {:error, :beam_lib, _reason} ->
              mapping
          end
      end

    computed_behaviour_mapping =
      for {module, behaviours} <- behaviours_by_module,
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
