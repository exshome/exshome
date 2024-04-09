defmodule ExshomeAutomationTest.Variables.DynamicVariable.VariableSupervisorTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.Datatype
  alias Exshome.Dependency.NotReady
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor
  alias ExshomeTest.TestRegistry

  import ExshomeTest.DynamicVariableHelpers

  test "no dynamic variables" do
    TestRegistry.start_dynamic_supervisor(VariableSupervisor)
  end

  test "starts with valid datatype" do
    datatype_name =
      Datatype.available_types()
      |> Enum.random()
      |> Datatype.name()

    %Schema{id: id} = Schema.create!(datatype_name)
    TestRegistry.start_dynamic_supervisor(VariableSupervisor)
    assert get_dynamic_variable_value(id) != NotReady
  end

  test "starts with invalid datatype" do
    %Schema{id: id} = create_dynamic_variable_with_unknown_type()
    TestRegistry.start_dynamic_supervisor(VariableSupervisor)
    assert get_dynamic_variable_value(id) != NotReady
  end
end
