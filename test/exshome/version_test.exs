defmodule ExshomeTest.VersionTest do
  use ExUnit.Case, async: true

  @app_version Application.spec(:exshome)[:vsn]

  test "version in launcher script" do
    launcher_script = read_file!(["..", "..", "bin", "exshome"])
    version_regex = ~r/^version = .*"#{@app_version}".*$/m
    assert launcher_script =~ version_regex
  end

  test "changelog entry for a revision" do
    changelog = read_file!(["..", "..", "CHANGELOG.md"])
    version_regex = ~r/^## v#{@app_version}/m
    assert changelog =~ version_regex
  end

  describe "dependency versions" do
    test "installation instructions for SBC" do
      installation_instructions = read_file!(["..", "..", "guides", "install_sbc.md"])

      for {tool, version} <- get_dependency_versions() do
        assert installation_instructions =~ "asdf plugin add #{tool}"
        assert installation_instructions =~ "asdf install #{tool} #{version}"
        assert installation_instructions =~ "asdf global #{tool} #{version}"
      end
    end

    defp get_dependency_versions do
      ["..", "..", ".tool-versions"]
      |> read_file!()
      |> String.split(~r/\R/)
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.map(&String.split(&1, ~r/\s+/))
      |> Enum.map(&List.to_tuple/1)
      |> Enum.into(%{})
    end
  end

  defp read_file!(location), do: location |> Path.join() |> Path.expand(__DIR__) |> File.read!()
end
