defmodule ExshomeAutomationTest.Variables.DynamicVariable.VariableSupervisorTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.Datatype
  alias Exshome.Subscribable.NotReady
  alias ExshomeAutomation.Variables.DynamicVariable.Schema

  import ExshomeTest.DynamicVariableHelpers

  test "no dynamic variables" do
    start_dynamic_variable_supervisor()
  end

  test "starts with valid datatype" do
    datatype = Enum.random(Datatype.available_types())
    %Schema{id: id} = Schema.create!(datatype.name())
    start_dynamic_variable_supervisor()
    assert get_dynamic_variable_value(id) != NotReady
  end

  test "starts with invalid datatype" do
    %Schema{id: id} = create_dynamic_variable_with_unknown_type()
    start_dynamic_variable_supervisor()
    assert get_dynamic_variable_value(id) != NotReady
  end
end
