defmodule Exshome.Settings do
  @moduledoc """
  Schema for storing application settings.
  """
  use Exshome.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false
  alias Exshome.Repo

  @callback default_values() :: %{atom() => any()}
  @callback changeset(Ecto.Changeset.t(t())) :: Ecto.Changeset.t(t())

  @primary_key {:name, :string, []}
  schema "service_settings" do
    field(:data, :map)
    field(:version, :integer)

    timestamps()
  end

  @type t() :: %__MODULE__{
          data: map(),
          version: integer(),
          name: String.t()
        }

  @spec get_or_create(name :: String.t(), default_data :: map()) :: map()
  def get_or_create(name, default_data) do
    %__MODULE__{data: data} =
      case Repo.get(__MODULE__, name) do
        nil ->
          Repo.insert!(%__MODULE__{
            name: name,
            data: default_data,
            version: 1
          })

        settings ->
          settings
      end

    data
  end

  @spec update!(name :: String.t(), (map() -> map()) | map()) :: map() | {:error, atom()}
  def update!(name, partial_data) when is_map(partial_data) do
    update!(name, &Map.merge(&1, partial_data))
  end

  def update!(name, update_fn) do
    %__MODULE__{data: data, version: version} = Repo.get!(__MODULE__, name)
    data = update_fn.(data)

    result =
      from(
        s in __MODULE__,
        where: s.name == ^name and s.version == ^version,
        select: s,
        update: [set: [data: ^data], inc: [version: 1]]
      )
      |> Repo.update_all([])

    case result do
      {1, [%__MODULE__{data: data}]} -> data
      _ -> {:error, :outdated_settings}
    end
  end

  @spec get_settings(arg :: module()) :: Ecto.Schema.t()
  def get_settings(module) when is_atom(module) do
    module
    |> get_module_name()
    |> get_or_create(module.default_values())
    |> from_map(module)
    |> set_default_values_for_errors()
  end

  @spec save_settings(Ecto.Schema.t()) :: Ecto.Schema.t() | {:error, Ecto.Changeset.t()}
  def save_settings(%module{} = data) do
    case valid_changes?(data) do
      {:ok, data} ->
        module
        |> get_module_name()
        |> update!(data)
        |> from_map(module)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @spec get_module_name(module()) :: String.t()
  def get_module_name(module), do: Atom.to_string(module)

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
        |> update!(default_values)
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

  defmacro __using__(fields: fields) do
    database_fields = Enum.map(fields, &{&1[:name], &1[:db_type]})
    typespec = Enum.map(fields, &{&1[:name], &1[:type]})

    quote do
      alias Exshome.Settings
      use Exshome.Schema
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
