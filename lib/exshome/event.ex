defmodule Exshome.Event do
  @moduledoc """
  An `m:Exshome.EmitterType`.
  Allows to publish events.
  """

  alias Exshome.Behaviours.EmitterTypeBehaviour

  @behaviour EmitterTypeBehaviour

  @impl EmitterTypeBehaviour
  def required_behaviours, do: MapSet.new()

  @impl EmitterTypeBehaviour
  def validate_message!(_), do: :ok
end
