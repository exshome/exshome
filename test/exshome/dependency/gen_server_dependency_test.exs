defmodule ExshomeTest.Dependency.GenServerDependencyTest do
  @moduledoc """
  Test GenServerDependency API.
  """
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  alias Exshome.Dependency.GenServerDependency

  describe "validate_module!/2" do
    test "calls validate_config!/2" do
      GenServerDependency.validate_module!(
        %Macro.Env{
          module: ExshomeClock.Services.UtcTime
        },
        "some_bytecode"
      )
    end
  end

  describe "validate_config!/1" do
    test "works fine with correct data" do
      GenServerDependency.validate_config!(name: "some_name")
    end

    test "raises for incorrect data" do
      assert_raise(NimbleOptions.ValidationError, fn ->
        GenServerDependency.validate_config!([])
      end)
    end
  end

  describe "DependencySupervisor" do
    alias GenServerDependency.DependencySupervisor

    test "start_link/1 works fine" do
      {:ok, pid} =
        %{}
        |> ExshomeTest.TestRegistry.prepare_child_opts()
        |> DependencySupervisor.start_link()

      modules =
        pid
        |> Supervisor.which_children()
        |> Enum.map(&elem(&1, 0))
        |> Enum.into(MapSet.new())

      all_modules =
        Exshome.App.apps()
        |> Enum.map(&GenServerDependency.modules/1)
        |> Enum.reduce(MapSet.new(), &MapSet.union/2)

      assert MapSet.equal?(all_modules, modules)
    end
  end
end
