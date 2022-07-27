defmodule ExshomeAutomation.Variables.DynamicVariable.Schema do
  @moduledoc """
  Schema for storing dynamic variable data.
  """

  use Exshome.Schema
  import Ecto.Query, warn: false
  alias Exshome.Repo

  schema "dynamic_variables" do
    field(:name, :string, default: "")
    field(:opts, :map)
    field(:type, :string)
    field(:value, :string)
    field(:version, :integer)

    timestamps()
  end

  @type t() :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          opts: map(),
          type: String.t(),
          value: String.t(),
          version: integer()
        }

  @spec get!(String.t()) :: t()
  def get!(id) when is_binary(id), do: Repo.get!(__MODULE__, id)

  @spec list() :: [t()]
  def list, do: Repo.all(__MODULE__)

  @spec create!(type :: String.t()) :: t()
  def create!(type) when is_binary(type) do
    Repo.insert!(%__MODULE__{
      opts: %{},
      type: type,
      version: 1
    })
  end

  @spec delete!(t()) :: t()
  def delete!(data) when is_struct(data, __MODULE__) do
    Repo.delete!(data)
  end
end
