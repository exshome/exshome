defmodule ExshomeTest do
  use ExUnit.Case
  doctest Exshome

  test "greets the world" do
    assert Exshome.hello() == :world
  end
end
