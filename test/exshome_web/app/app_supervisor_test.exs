defmodule ExshomeWebTest.App.AppSupervisorTest do
  use Exshome.DataCase, async: true
  alias Exshome.Dependency.GenServerDependency
  alias ExshomeWeb.App
  alias ExshomeWeb.App.AppSupervisor

  describe "AppSupervisor" do
    test "start_link/1 works fine" do
      {:ok, pid} =
        %{}
        |> ExshomeTest.TestRegistry.prepare_child_opts()
        |> Map.put(:supervisor_opts, name: nil)
        |> AppSupervisor.start_link()

      modules =
        pid
        |> Supervisor.which_children()
        |> Enum.map(&elem(&1, 0))
        |> Enum.into(MapSet.new())

      all_modules =
        App.apps()
        |> Enum.map(&GenServerDependency.modules/1)
        |> Enum.flat_map(&MapSet.to_list/1)
        |> Enum.map(& &1.get_child_module())
        |> Enum.into(MapSet.new())

      assert MapSet.equal?(all_modules, modules)
      Supervisor.stop(pid)
    end

    test "start_link/1 starts only selected apps" do
      for app <- App.apps() do
        {:ok, pid} =
          %{apps: [app]}
          |> ExshomeTest.TestRegistry.prepare_child_opts()
          |> Map.put(:supervisor_opts, name: nil)
          |> AppSupervisor.start_link()

        modules =
          pid
          |> Supervisor.which_children()
          |> Enum.map(&elem(&1, 0))
          |> Enum.into(MapSet.new())

        app_modules =
          app
          |> GenServerDependency.modules()
          |> Enum.map(& &1.get_child_module())
          |> Enum.into(MapSet.new())

        assert MapSet.equal?(app_modules, modules)
        Supervisor.stop(pid)
      end
    end
  end
end
