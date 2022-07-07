defmodule Exshome.SystemRegistry do
  @moduledoc """
  System-wide registry.
  """
  @spec child_spec(opts :: any()) :: Supervisor.child_spec()
  def child_spec(_opts), do: Registry.child_spec(keys: :unique, name: __MODULE__)

  @spec register!(module(), id :: any(), value :: any()) :: :ok
  def register!(module, id, value) when is_atom(module) do
    module
    |> registry_key(id)
    |> put!(value)
  end

  @spec update_value!(module(), id :: any(), (any() -> any())) :: :ok
  def update_value!(module, id, value_fn) do
    key = registry_key(module, id)
    {_, _} = Registry.update_value(__MODULE__, key, value_fn)
    :ok
  end

  @spec list(module()) :: list()
  def list(module) when is_atom(module) do
    Registry.select(
      __MODULE__,
      [
        {
          {registry_key(module, :_), :_, :"$1"},
          [],
          [:"$1"]
        }
      ]
    )
  end

  @spec get_by_id(module(), id :: any()) :: {:ok, any()} | {:error, String.t()}
  def get_by_id(module, id) when is_atom(module) do
    module
    |> registry_key(id)
    |> get()
  end

  @spec put!(key :: any(), value :: any()) :: :ok
  def put!(key, value) do
    {:ok, _} = Registry.register(__MODULE__, key, value)
    :ok
  end

  @spec get!(key :: any()) :: any()
  def get!(key) do
    case get(key) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  @spec get(any()) :: {:ok, any()} | {:error, String.t()}
  def get(key) do
    case Registry.lookup(__MODULE__, key) do
      [{_, value}] -> {:ok, value}
      _ -> {:error, "Unable to find a value for a key #{inspect(key)}"}
    end
  end

  defp registry_key(module, id) when is_atom(module) do
    {module, id}
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(registry_key: 2)
    defdelegate registry_key(module, id), to: @hook_module
  end
end
