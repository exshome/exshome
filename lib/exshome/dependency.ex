defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  use Exshome.Subscribable
  @type dependency() :: Subscribable.subscription()
  @type value() :: Subscribable.value()
  @type dependency_mapping() :: Subscribable.subscription_mapping()

  @callback get_value(dependency()) :: value()

  defmacro __using__(_) do
    quote do
      alias Exshome.Dependency
      alias Exshome.Subscribable.NotReady
      @behaviour Dependency
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Dependency)
    end
  end
end
