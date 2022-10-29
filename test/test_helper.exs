ExUnit.start()

ExUnit.after_suite(fn _ ->
  File.rm_rf!(ExshomeTest.TestFileUtils.test_root_folder())
end)
