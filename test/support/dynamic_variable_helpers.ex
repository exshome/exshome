defmodule ExshomeTest.DynamicVariableHelpers do
  @moduledoc """
  Helper functions for testing dynamic variables.
  """

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias Exshome.Repo
  alias ExshomeAutomation.Variables.DynamicVariable
  alias ExshomeAutomation.Variables.DynamicVariable.Schema

  @spec get_dynamic_variable_value(String.t()) :: Dependency.value()
  def get_dynamic_variable_value(id) when is_binary(id) do
    Dependency.get_value({DynamicVariable, id})
  end

  @spec create_dynamic_variable_with_unknown_type() :: Schema.t()
  def create_dynamic_variable_with_unknown_type do
    {:ok, schema} =
      Repo.insert(%Schema{
        type: "unknown_datatype#{unique_integer()}"
      })

    schema
  end
end
