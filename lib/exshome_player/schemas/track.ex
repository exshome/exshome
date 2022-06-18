defmodule ExshomePlayer.Schemas.Track do
  @moduledoc """
  Player track data.
  """

  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset
  use Exshome.Schema
  alias Ecto.Changeset
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
          type: :url | :file,
          path: String.t() | nil
        }

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t()
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :type, :path])
    |> validate_required([:type, :path])
    |> validate_inclusion(:type, @types)
    |> validate_path_format()
  end

  @spec get!(String.t()) :: t()
  def get!(id) when is_binary(id), do: Repo.get!(__MODULE__, id)

  @spec list() :: [t()]
  def list, do: from(__MODULE__, order_by: [desc: :type, asc: :path]) |> Repo.all()

  @spec get_or_create_by_path(String.t()) :: t()
  def get_or_create_by_path(path) when is_binary(path) do
    case Repo.get_by(__MODULE__, path: path) do
      %__MODULE__{} = result -> result
      nil -> create!(%{path: path})
    end
  end

  @spec create!(map()) :: t()
  def create!(data) do
    {:ok, result} = create(data)
    result
  end

  @spec create(map()) :: {:ok, t()} | {:error, Changeset.t(t())}
  def create(data) do
    %__MODULE__{}
    |> changeset(data)
    |> Repo.insert()
    |> case do
      {:ok, result} ->
        Event.broadcast(%TrackEvent{action: :created, track: result})
        {:ok, result}

      result ->
        result
    end
  end

  @spec update!(t(), map()) :: t()
  def update!(%__MODULE__{} = track, %{} = data) do
    {:ok, result} = update(track, data)
    result
  end

  @spec update(t(), map()) :: {:ok, t()} | {:error, Changeset.t(t())}
  def update(%__MODULE__{} = track, %{} = data) do
    track
    |> changeset(data)
    |> Repo.update()
    |> case do
      {:ok, result} ->
        Event.broadcast(%TrackEvent{action: :updated, track: result})
        {:ok, result}

      result ->
        result
    end
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

  @spec validate_path_format(Changeset.t()) :: Changeset.t()
  defp validate_path_format(%Changeset{} = changeset) do
    type = get_field(changeset, :type)

    case type do
      :url -> validate_format(changeset, :path, ~r{^https?://})
      _ -> changeset
    end
  end
end
