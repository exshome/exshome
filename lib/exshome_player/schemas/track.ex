defmodule ExshomePlayer.Schemas.Track do
  @moduledoc """
  Player track data.
  """

  import Ecto.Query
  import Ecto.Changeset
  use Exshome.Schema
  alias Exshome.Event
  alias Exshome.Repo
  alias ExshomePlayer.Events.TrackEvent
  alias ExshomePlayer.Services.MpvServer

  @types [:file, :url]

  schema "player_tracks" do
    field(:title, :string, default: "")
    field(:type, Ecto.Enum, values: @types, default: :file)
    field(:path, :string)

    timestamps()
  end

  @type t() :: %__MODULE__{
          title: String.t() | nil,
          type: String.t() | :file,
          path: String.t()
        }

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :type, :path])
    |> validate_required([:type, :path])
    |> validate_inclusion(:type, @types)
  end

  @spec get!(String.t()) :: t()
  def get!(id) when is_binary(id), do: Repo.get!(__MODULE__, id)

  @spec list() :: [t()]
  def list, do: Repo.all(__MODULE__)

  @spec get_or_create_by_path(String.t()) :: t()
  def get_or_create_by_path(path) when is_binary(path) do
    case Repo.get_by(__MODULE__, path: path) do
      %__MODULE__{} = result -> result
      nil -> create!(%__MODULE__{path: path})
    end
  end

  @spec create!(t()) :: t()
  def create!(%__MODULE__{} = data) do
    result =
      data
      |> changeset()
      |> Repo.insert!()

    Event.broadcast(%TrackEvent{action: :created, track: result})

    result
  end

  @spec update!(t(), map()) :: t()
  def update!(%__MODULE__{} = track, %{} = data) do
    result =
      track
      |> changeset(data)
      |> Repo.update!()

    Event.broadcast(%TrackEvent{action: :updated, track: result})
    result
  end

  @spec delete!(t()) :: :ok
  def delete!(%__MODULE__{} = track) do
    Repo.delete!(track)
    Event.broadcast(%TrackEvent{track: track, action: :deleted})
    on_delete(track)
  end

  @spec refresh_tracklist() :: :ok
  def refresh_tracklist do
    music_folder = MpvServer.music_folder()

    files =
      music_folder
      |> Path.join("**/*.*")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, music_folder))
      |> Enum.into(MapSet.new())

    Enum.each(files, &get_or_create_by_path/1)

    from(t in __MODULE__, where: t.type == :file)
    |> Repo.all()
    |> Enum.reject(&MapSet.member?(files, &1.path))
    |> Enum.each(&delete!/1)

    :ok
  end

  @spec url(t()) :: String.t()
  def url(%__MODULE__{type: :url, path: path}), do: path

  def url(%__MODULE__{type: :file, path: path}) do
    Path.join(MpvServer.music_folder(), path)
  end

  @spec on_delete(t()) :: :ok
  defp on_delete(%__MODULE__{type: :file} = track) do
    track
    |> url()
    |> File.rm!()
  end

  defp on_delete(%__MODULE__{}), do: :ok
end
