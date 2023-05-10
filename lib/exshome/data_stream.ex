defmodule Exshome.DataStream do
  @moduledoc """
  Contains all DataStream-related features.
  """
  use Exshome.Subscribable
  @type stream() :: Subscribable.subscription()
  @type value() :: Subscribable.value()
  @type stream_mapping() :: Subscribable.subscription_mapping()

  @callback get_value(stream()) :: value()

  defmacro __using__(name: name) do
    quote do
      alias Exshome.DataStream
      use Exshome.Named, "event:#{unquote(name)}"
      @behaviour DataStream
      add_tag(DataStream)
    end
  end
end
