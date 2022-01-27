defmodule Exshome.Settings do
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

  @spec get_or_create(name :: String.t(), default_data :: map()) :: t()
  def get_or_create(name, default_data) do
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
  end

  @spec update!(name :: String.t(), partial_data :: map()) :: t()
  def update!(name, partial_data) do
    %__MODULE__{} = settings = Repo.get!(__MODULE__, name)
    data = Map.merge(settings.data, partial_data)

    {1, [result]} =
      from(
        s in __MODULE__,
        where: s.name == ^name and s.version == ^settings.version,
        select: s,
        update: [set: [data: ^data], inc: [version: 1]]
      )
      |> Repo.update_all([])

    result
  end
end
