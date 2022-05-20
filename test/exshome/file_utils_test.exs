defmodule ExshomeTest.FileUtilsTest do
  use ExUnit.Case, async: true
  alias Exshome.FileUtils
  alias ExshomeTest.{TestFileUtils, TestRegistry}

  setup do
    TestRegistry.allow(self(), self())
    TestFileUtils.generate_test_folder()
    :ok
  end

  describe "get_or_create_test_folder!/1" do
    test "creates folder" do
      folder_name = Ecto.UUID.generate()

      expected_path =
        Path.join(
          TestFileUtils.get_test_folder(),
          folder_name
        )

      refute File.exists?(expected_path)
      assert FileUtils.get_of_create_folder!(folder_name) == expected_path
      assert File.dir?(expected_path)
    end

    test "raises for folder that is located out of root one" do
      assert_raise RuntimeError, fn ->
        FileUtils.get_of_create_folder!("..")
      end
    end

    test "works fine with root-related path" do
      folder_name = Ecto.UUID.generate()

      assert FileUtils.get_of_create_folder!(folder_name) ==
               FileUtils.get_of_create_folder!("/#{folder_name}")
    end
  end
end
