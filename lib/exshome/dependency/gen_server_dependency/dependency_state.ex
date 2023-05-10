defmodule Exshome.Dependency.GenServerDependency.DependencyState do
  @moduledoc """
  Inner state for each dependency.
  """
  alias Exshome.Subscribable

  defstruct [
    :data,
    :dependency,
    :opts,
    deps: %{},
    private: %{},
    value: Subscribable.NotReady
  ]

  @type t() :: %__MODULE__{
          data: any(),
          dependency: Subscribable.subscription(),
          deps: map(),
          opts: any(),
          private: map(),
          value: Subscribable.value()
        }
end
