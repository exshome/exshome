defmodule Exshome.Settings do
  @moduledoc """
  Settings module.
  """
  import Ecto.Changeset
  alias Exshome.Settings.Schema

  @callback default_values() :: %{atom() => any()}
  @callback changeset(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  @spec get_settings(arg :: module()) :: Ecto.Schema.t()
  def get_settings(module) when is_atom(module) do
    module
    |> get_module_name()
    |> Schema.get_or_create(module.default_values())
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
        default_values =
          for field <- Keyword.keys(changeset.errors), into: %{} do
            {field, module.default_values()[field]}
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
    |> cast(data, Map.keys(module.default_values()))
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
    available_keys = Map.keys(module.default_values())

    module
    |> struct(%{})
    |> Ecto.Changeset.cast(data, available_keys)
    |> Ecto.Changeset.validate_required(available_keys)
    |> module.changeset()
  end

  @spec available_modules() :: MapSet.t(atom())
  def available_modules do
    Exshome.Tag.tag_mapping() |> Map.fetch!(__MODULE__)
  end

  defmacro __using__(settings) do
    name = Keyword.fetch!(settings, :name)
    fields = Keyword.fetch!(settings, :fields)
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
      @default_values unquote(Enum.map(fields, fn {name, data} -> {name, data[:default]} end))
                      |> Enum.into(%{})

      @primary_key false
      embedded_schema do
        @derive {Jason.Encoder, only: Map.keys(@default_values)}
        for {field_name, db_type} <- unquote(database_fields) do
          field(field_name, db_type)
        end
      end

      @type t() :: %__MODULE__{unquote_splicing(database_fields)}

      add_tag(Settings)

      @impl Settings
      def default_values, do: @default_values

      @impl Exshome.Dependency
      def get_value, do: Settings.get_settings(__MODULE__)
    end
  end
end
