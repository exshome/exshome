defmodule Exshome.Behaviours.EmitterBehaviour do
  @moduledoc """
  Allows to create a module to use with `m:Exshome.Emitter`.
  """

  @doc """
  All child events should implement this behaviour.
  """
  @callback child_behaviour() :: module()

  @doc """
  Extracts child module from identifier.
  """
  @callback child_module(child_identifier :: term()) :: module()

  @doc """
  Generates a topic name for the child event.
  """
  @callback pub_sub_topic(child_identifer :: term()) :: String.t()

  @doc """
  Prefix for each pub sub topic.
  """
  @callback topic_prefix() :: String.t()
end
