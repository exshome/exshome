defmodule Exshome.BehaviourMapping do
  @moduledoc """
  Computes mapping for all behaviours in application.
  """

  @behaviour_mapping_key __MODULE__
  @mapping_not_found :not_found

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

    result =
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

    :persistent_term.put(@behaviour_mapping_key, result)
    result
  end

  def mapping do
    case :persistent_term.get(@behaviour_mapping_key, @mapping_not_found) do
      @mapping_not_found ->
        recompute_mapping()

      result ->
        result
    end
  end
end
