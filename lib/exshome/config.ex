defmodule Exshome.Config do
  @moduledoc """
  Stores application-wide configuration.
  """

  @doc """
  Root data folder.
  It stores all user data.
  """
  @spec root_folder() :: String.t()
  def root_folder do
    Application.get_env(:exshome, :root_folder)
  end

  @doc """
  Default timeout for different GenServer-based calls.
  """
  @spec default_timeout() :: timeout()
  def default_timeout, do: 5000

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(default_timeout: 0, root_folder: 0)
    defdelegate default_timeout, to: @hook_module
    defdelegate root_folder, to: @hook_module
  end
end
