defmodule Exshome.Settings.Schema do
  @moduledoc """
  Schema for storing application settings.
  """
  use Exshome.Schema

  import Ecto.Query, warn: false
  alias Exshome.Repo

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
end
