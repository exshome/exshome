defmodule ExshomeWebTest.App.AppSupervisorTest do
  use ExshomeTest.DataCase, async: true
  alias Exshome.Service
  alias ExshomeWeb.App
  alias ExshomeWeb.App.AppSupervisor

  describe "AppSupervisor" do
    test "start_link/1 works fine" do
      {:ok, pid} =
        %{}
        |> ExshomeTest.TestRegistry.prepare_child_opts()
        |> Map.put(:supervisor_opts, name: nil)
        |> AppSupervisor.start_link()

      started_modules = get_started_dependencies(pid)

      all_modules = get_child_modules_for_apps(App.apps())

      assert MapSet.equal?(all_modules, started_modules)
      Supervisor.stop(pid)
    end

    test "start_link/1 starts only selected apps" do
      for app <- App.apps() do
        {:ok, pid} =
          %{apps: [app]}
          |> ExshomeTest.TestRegistry.prepare_child_opts()
          |> Map.put(:supervisor_opts, name: nil)
          |> AppSupervisor.start_link()

        started_modules = get_started_dependencies(pid)

        app_modules = get_child_modules_for_apps([app])

        assert MapSet.equal?(app_modules, started_modules)
        Supervisor.stop(pid)
      end
    end
  end

  defp get_started_dependencies(pid) do
    pid
    |> Supervisor.which_children()
    |> Enum.map(&elem(&1, 1))
    |> Enum.flat_map(&Supervisor.which_children/1)
    |> Enum.map(&elem(&1, 0))
    |> Enum.into(MapSet.new())
  end

  defp get_child_modules_for_apps(apps) do
    apps
    |> Enum.map(&Service.app_modules/1)
    |> Enum.flat_map(&MapSet.to_list/1)
    |> Enum.map(& &1.get_parent_module())
    |> Enum.into(MapSet.new())
  end
end
