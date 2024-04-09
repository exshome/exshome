defmodule Exshome.Service.ServiceState do
  @moduledoc """
  Inner state of each service.
  """
  alias Exshome.Dependency

  defstruct [
    :id,
    :data,
    :module,
    :opts,
    deps: %{},
    private: %{},
    value: Dependency.NotReady
  ]

  @type t() :: %__MODULE__{
          id: Exshome.Id.t(),
          data: term(),
          deps: map(),
          module: module(),
          opts: term(),
          private: map(),
          value: Dependency.value()
        }
end
