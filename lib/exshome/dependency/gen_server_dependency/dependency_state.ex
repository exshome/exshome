defmodule Exshome.Dependency.GenServerDependency.DependencyState do
  @moduledoc """
  Inner state for each dependency.
  """
  alias Exshome.Dependency

  defstruct [:dependency, :opts, :deps, :data, value: Dependency.NotReady]

  @type t() :: %__MODULE__{
          dependency: Dependency.dependency(),
          deps: map(),
          data: any(),
          opts: any(),
          value: Exshome.Dependency.value()
        }
end
