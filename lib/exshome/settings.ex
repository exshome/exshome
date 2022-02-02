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
        module
        |> get_module_name()
        |> Schema.update!(data)
        |> from_map(module)

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
  def valid_changes?(%module{} = data) do
    available_keys = Map.keys(module.default_values())

    module
    |> struct(%{})
    |> Ecto.Changeset.cast(Map.from_struct(data), available_keys)
    |> Ecto.Changeset.validate_required(available_keys)
    |> module.changeset()
    |> Ecto.Changeset.apply_action(:update)
  end

  @spec available_modules() :: MapSet.t(atom())
  def available_modules do
    Exshome.Tag.tag_mapping() |> Map.fetch!(__MODULE__)
  end

  defmacro __using__(settings) do
    name = Keyword.fetch!(settings, :name)
    fields = Keyword.fetch!(settings, :fields)
    database_fields = Enum.map(fields, &{&1[:name], &1[:db_type]})
    typespec = Enum.map(fields, &{&1[:name], &1[:type]})

    quote do
      alias Exshome.Settings
      use Exshome.Schema
      use Exshome.Named, unquote(name)
      import Ecto.Changeset

      import Exshome.Tag, only: [add_tag: 1]
      @behaviour Settings
      @default_values unquote(Enum.map(fields, &{&1[:name], &1[:default]})) |> Enum.into(%{})

      @primary_key false
      embedded_schema do
        @derive {Jason.Encoder, only: Map.keys(@default_values)}
        for {field_name, db_type} <- unquote(database_fields) do
          field(field_name, db_type)
        end
      end

      @type t() :: %__MODULE__{unquote_splicing(typespec)}

      add_tag(Settings)

      @impl Settings
      def default_values, do: @default_values
    end
  end
end
