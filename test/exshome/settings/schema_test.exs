defmodule ExshomeTest.Settings.SchemaTest do
  use ExshomeTest.DataCase, async: true
  alias Exshome.Settings.Schema
  alias ExshomeTest.Fixtures

  describe "schema get_or_create/2" do
    test "creates new settings or returns existing ones" do
      settings_name = "settings_#{Fixtures.unique_integer()}"
      default_data = %{"key_#{Fixtures.unique_integer()}" => "some_value"}
      create_result = Schema.get_or_create(settings_name, default_data)

      assert default_data = create_result

      another_data = %{"key_#{Fixtures.unique_integer()}" => "some_value"}
      existing_result = Schema.get_or_create(settings_name, another_data)
      assert default_data == existing_result
    end
  end

  describe "schema update!/2" do
    setup do
      name = "settings_#{Fixtures.unique_integer()}"
      default_data = %{"key_#{Fixtures.unique_integer()}" => "some_value"}
      data = Schema.get_or_create(name, default_data)
      %{name: name, data: data}
    end

    test "adds extra fields, keeps exsisting ones", %{name: name, data: data} do
      extra_data = %{"key_#{Fixtures.unique_integer()}" => "extra value"}
      assert new_data = Schema.update!(name, extra_data)
      compare_data(data, new_data)
      compare_data(extra_data, new_data)
    end

    test "fails for unknown settings" do
      unknown_settings = "settings_#{Fixtures.unique_integer()}"

      assert_raise(Ecto.NoResultsError, fn ->
        Schema.update!(unknown_settings, %{})
      end)
    end

    test "updates the existing value", %{name: name, data: data} do
      existing_key = data |> Map.keys() |> List.first()
      random_value = Fixtures.unique_integer()
      refute data[existing_key] == random_value

      new_data = %{existing_key => random_value}
      assert ^new_data = Schema.update!(name, new_data)
    end

    test "fails to update while a race condition", %{name: name} do
      ref = make_ref()
      test_pid = self()

      update_fn = fn _data ->
        send(test_pid, {self(), ref})

        receive do
          ^ref ->
            %{}
        end
      end

      task =
        Task.async(fn ->
          ExshomeTest.TestRegistry.allow(test_pid, self())
          Schema.update!(name, update_fn)
        end)

      receive do
        {pid, ^ref} ->
          Schema.update!(name, %{})
          send(pid, ref)
      end

      assert {:error, _reason} = Task.await(task)
    end

    defp compare_data(%{} = expected, %{} = existing) do
      data =
        for key <- Map.keys(expected), into: %{} do
          {key, existing[key] || :unknown_value}
        end

      assert expected == data
    end
  end
end
