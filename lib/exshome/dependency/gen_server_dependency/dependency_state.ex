defmodule Exshome.Dependency.GenServerDependency.DependencyState do
  @moduledoc """
  Inner state for each dependency.
  """

  defstruct [:module, :opts, :deps, :data, value: Dependency.NotReady]

  @type t() :: %__MODULE__{
          module: module(),
          deps: map(),
          data: any(),
          opts: any(),
          value: Exshome.Dependency.value()
        }
end
