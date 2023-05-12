defmodule Exshome.Dependency.GenServerDependency.DependencyState do
  @moduledoc """
  Inner state for each dependency.
  """
  alias Exshome.Dependency

  defstruct [
    :data,
    :dependency,
    :opts,
    deps: %{},
    private: %{},
    value: Dependency.NotReady
  ]

  @type t() :: %__MODULE__{
          data: any(),
          dependency: Dependency.dependency(),
          deps: map(),
          opts: any(),
          private: map(),
          value: Dependency.value()
        }
end
