defmodule ExshomeTest.MacroHelpers do
  @moduledoc """
  Helpers to test macrogeneration.
  """

  defmacro compile_with_settings(module, settings) do
    quote do
      require unquote(module)
      configuration = unquote(settings)
      module_to_test = unquote(module)

      quote do
        unquote(module_to_test).__using__(unquote(configuration))
      end
      |> Macro.expand(__ENV__)
      |> Macro.to_string()
    end
  end
end
