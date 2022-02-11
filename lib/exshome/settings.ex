defmodule Exshome.Settings do
  @moduledoc """
  Settings module.
  """
  import Ecto.Changeset
  alias Exshome.Settings.Schema

  @callback fields() :: term()

  @spec get_settings(arg :: module()) :: Ecto.Schema.t()
  def get_settings(module) when is_atom(module) do
    module
    |> get_module_name()
    |> Schema.get_or_create(default_values(module))
    |> from_map(module)
    |> set_default_values_for_errors()
  end

  @spec save_settings(Ecto.Schema.t()) :: Ecto.Schema.t() | {:error, Ecto.Changeset.t()}
  def save_settings(%module{} = data) do
    case valid_changes?(data) do
      {:ok, data} ->
        result =
          module
          |> get_module_name()
          |> Schema.update!(data)
          |> from_map(module)

        Exshome.Dependency.broadcast_value(module, result)
        result

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @spec get_module_name(module()) :: String.t()
  def get_module_name(module) do
    if module in available_modules() do
      module.name()
    else
      raise "#{inspect(module)} is not valid settings!"
    end
  end

  @spec set_default_values_for_errors(Ecto.Schema.t()) :: Ecto.Schema.t()
  defp set_default_values_for_errors(%module{} = data) do
    case valid_changes?(data) do
      {:ok, result} ->
        result

      {:error, %Ecto.Changeset{} = changeset} ->
        module_default_values = default_values(module)

        default_values =
          for field <- Keyword.keys(changeset.errors), into: %{} do
            {field, module_default_values[field]}
          end

        module
        |> get_module_name()
        |> Schema.update!(default_values)
        |> from_map(module)
    end
  end

  defp from_map(data, module) do
    module
    |> struct!()
    |> cast(data, module.fields() |> Keyword.keys())
    |> apply_changes()
  end

  @spec valid_changes?(struct()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def valid_changes?(data) do
    data
    |> changeset()
    |> Ecto.Changeset.apply_action(:update)
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  def changeset(%module{} = data), do: changeset(module, Map.from_struct(data))

  @spec changeset(module(), map()) :: Ecto.Changeset.t()
  def changeset(module, data) do
    fields = module.fields()
    available_keys = Keyword.keys(fields)
    required_fields = for {field, data} <- fields, data[:required], do: field

    allowed_fields =
      for {field, data} <- fields, data[:allowed_values] do
        {field, data[:allowed_values]}
      end

    module
    |> struct(%{})
    |> Ecto.Changeset.cast(data, available_keys)
    |> Ecto.Changeset.validate_required(required_fields)
    |> check_allowed_values(allowed_fields)
  end

  @spec available_modules() :: MapSet.t(atom())
  def available_modules do
    Exshome.Tag.tag_mapping() |> Map.fetch!(__MODULE__)
  end

  @spec default_values(module()) :: map()
  def default_values(module) when is_atom(module) do
    module.fields()
    |> Enum.map(fn {field, data} -> {field, data[:default]} end)
    |> Enum.into(%{})
  end

  defp check_allowed_values(changeset, allowed_fields) do
    for {field, values_fn} <- allowed_fields, reduce: changeset do
      ch -> validate_inclusion(ch, field, values_fn.())
    end
  end

  defmacro __using__(config) do
    config |> Macro.expand(__ENV__) |> validate_config!()
    name = Keyword.fetch!(config, :name)
    fields = Keyword.fetch!(config, :fields)
    database_fields = Enum.map(fields, fn {name, data} -> {name, data[:type]} end)

    quote do
      alias Exshome.DataType
      alias Exshome.Settings
      use Exshome.Schema
      use Exshome.Named, unquote(name)
      use Exshome.Dependency
      import Ecto.Changeset

      import Exshome.Tag, only: [add_tag: 1]
      @behaviour Settings

      @primary_key false
      embedded_schema do
        @derive {Jason.Encoder, only: Keyword.keys(unquote(fields))}
        for {field_name, db_type} <- unquote(database_fields) do
          field(field_name, db_type)
        end
      end

      @type t() :: %__MODULE__{unquote_splicing(database_fields)}

      add_tag(Settings)

      @impl Exshome.Dependency
      def get_value, do: Settings.get_settings(__MODULE__)

      @impl Settings
      def fields, do: unquote(fields)
    end
  end

  defp validate_config!(config) do
    validation_schema = [
      name: [
        type: :string,
        required: true
      ],
      fields: [
        type: :keyword_list,
        keys: [
          *: [
            keys: [
              allowed_values: [
                type: :any
              ],
              default: [
                type: :any,
                required: true
              ],
              required: [
                type: :boolean,
                required: true
              ],
              type: [
                type: :atom,
                required: true
              ]
            ]
          ]
        ]
      ]
    ]

    Exshome.Validation.validate_config!(config, validation_schema)
  end
end
