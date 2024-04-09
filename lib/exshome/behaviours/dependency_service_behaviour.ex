defmodule Exshome.Behaviours.DependencyServiceBehaviour do
  @moduledoc """
  Features related to the DependencyService.
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Id
  alias Exshome.Service.ServiceState

  @callback handle_dependency_change(state :: ServiceState.t()) :: ServiceState.t()
  @callback handle_service(
              {service_id :: Id.t(), value :: term()},
              state :: ServiceState.t()
            ) :: ServiceState.t()
  @callback handle_stream(
              {stream_id :: Id.t(), operation :: Operation.single_operation()},
              state :: ServiceState.t()
            ) :: ServiceState.t()
  @callback handle_event(event_id :: Id.t(), state :: ServiceState.t()) :: ServiceState.t()

  @optional_callbacks [
    handle_dependency_change: 1,
    handle_event: 2,
    handle_service: 2,
    handle_stream: 2
  ]
end
