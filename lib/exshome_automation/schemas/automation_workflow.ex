defmodule ExshomeAutomation.Schemas.AutomationWorkflow do
  @moduledoc """
  Schema for storing automation workflow data.
  """
  use Exshome.Schema
  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Exshome.Repo

  schema "automation_workflows" do
    field(:name, :string, default: "")
    field(:version, :integer)

    timestamps()
  end

  @type t() :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          version: integer()
        }

  @spec get!(String.t()) :: t()
  def get!(id) when is_binary(id), do: Repo.get!(__MODULE__, id)

  @spec list() :: [t()]
  def list, do: Repo.all(__MODULE__)

  @spec create!() :: t()
  def create! do
    Repo.insert!(%__MODULE__{
      name: "new workflow",
      version: 1
    })
  end

  @spec rename!(t(), String.t()) :: t()
  def rename!(%__MODULE__{} = data, name) when is_binary(name) do
    update!(data, %{name: name})
  end

  @spec update!(t(), map()) :: t()
  def update!(%__MODULE__{} = data, %{} = params) do
    data
    |> Changeset.cast(params, [:name])
    |> Changeset.optimistic_lock(:version)
    |> Repo.update!()
  end

  @spec delete!(t()) :: t()
  def delete!(data) when is_struct(data, __MODULE__) do
    Repo.delete!(data)
  end
end
