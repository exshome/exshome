defmodule Exshome.Behaviours.DatatypeBehaviour do
  @moduledoc """
  Allows to implement a custom datatype.
  """
  alias Exshome.Behaviours.DatatypeBehaviour

  @callback __datatype_config__() :: keyword()
  @callback to_string(value :: any()) :: {:ok, String.t()} | {:error, String.t()}
  @callback validate(value :: any(), validation :: atom(), opts :: any()) ::
              {:ok, any()} | {:error, String.t()}

  @optional_callbacks [validate: 3]

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    NimbleOptions.validate!(
      module.__datatype_config__(),
      base_type: [
        type: :atom,
        required: true
      ],
      default: [
        type: :any,
        required: true
      ],
      icon: [
        type: :string,
        required: true
      ],
      name: [
        type: :string,
        required: true
      ],
      validations: [
        type: {:list, :atom}
      ]
    )
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.Behaviours.DatatypeBehaviour

      use Ecto.Type

      @after_compile {DatatypeBehaviour, :validate_module!}
      @behaviour DatatypeBehaviour

      @impl DatatypeBehaviour
      def __datatype_config__, do: unquote(config)

      @impl Ecto.Type
      def type, do: unquote(config[:base_type])

      @impl Ecto.Type
      def cast(data), do: Ecto.Type.cast(type(), data)

      @impl Ecto.Type
      def dump(data), do: Ecto.Type.dump(type(), data)

      @impl Ecto.Type
      def load(data), do: Ecto.Type.load(type(), data)

      defoverridable(Ecto.Type)
    end
  end
end
