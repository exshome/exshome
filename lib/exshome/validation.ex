defmodule Exshome.Validation do
  @moduledoc """
  Validation utils.
  """
  def validate_config!(config, schema) do
    config
    |> expand()
    |> NimbleOptions.validate!(schema)
  end

  defp expand({key, value}), do: {expand(key), expand(value)}
  defp expand(values) when is_list(values), do: Enum.map(values, &expand/1)
  defp expand(value), do: Macro.expand(value, __ENV__)
end
