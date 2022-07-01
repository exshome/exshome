defmodule Exshome.SystemRegistry do
  @moduledoc """
  System-wide registry.
  """
  @spec child_spec(opts :: any()) :: Supervisor.child_spec()
  def child_spec(_opts), do: Registry.child_spec(keys: :unique, name: __MODULE__)

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

  @spec select(Registry.spec()) :: [term()]
  def select(spec), do: Registry.select(__MODULE__, spec)
end
