defmodule Exshome.Dependency.GenServerDependency.DependencyState do
  @moduledoc """
  Inner state for each dependency.
  """
  alias Exshome.Dependency
  alias Exshome.Emitter

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
          dependency: Emitter.id(),
          deps: map(),
          opts: any(),
          private: map(),
          value: Dependency.value()
        }
end
