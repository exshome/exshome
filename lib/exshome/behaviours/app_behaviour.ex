defmodule Exshome.Behaviours.AppBehaviour do
  @moduledoc """
  Behaviour for exshome applications.
  """

  defstruct [:pages, :prefix, :preview]

  @type t() :: %__MODULE__{
          pages: [atom()],
          prefix: String.t(),
          preview: atom()
        }

  @callback app_settings() :: t()

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)

      @behaviour unquote(__MODULE__)
    end
  end
end
