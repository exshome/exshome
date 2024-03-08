defmodule Exshome.Id do
  @moduledoc """
  Provides types and operations with identifiers.
  """

  @type t() :: module() | {module(), String.t()}

  @doc """
  Extracts module from the identifier.
  """
  @spec get_module(t()) :: module()
  def get_module({module, identifier}) when is_atom(module) and is_binary(identifier), do: module
  def get_module(module) when is_atom(module), do: module
end
