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

  test "dependency version in docs" do
    dependency_data =
      ["..", "..", ".tool-versions"]
      |> read_file!()
      |> String.split(~r/\R/)

    installation_instructions = read_file!(["..", "..", "guides", "install_sbc.md"])

    for line <- dependency_data, String.trim(line) != "", [tool, version] = String.split(line) do
      assert installation_instructions =~ "asdf plugin add #{tool}"
      assert installation_instructions =~ "asdf install #{tool} #{version}"
      assert installation_instructions =~ "asdf global #{tool} #{version}"
    end
  end

  defp read_file!(location), do: location |> Path.join() |> Path.expand(__DIR__) |> File.read!()
end
