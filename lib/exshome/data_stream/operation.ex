defmodule Exshome.DataStream.Operation do
  @moduledoc """
  Contains DataStream Operations.
  """

  defmodule Insert do
    @moduledoc """
    Insert operation.
    """
    defstruct [:operation_id, :data, at: -1]

    @type t() :: %__MODULE__{
            operation_id: Exshome.DataStream.Operation.operation_id(),
            data: struct(),
            at: integer()
          }
  end

  defmodule Update do
    @moduledoc """
    Update operation.
    """
    defstruct [:operation_id, :data, at: -1]

    @type t() :: %__MODULE__{
            operation_id: Exshome.DataStream.Operation.operation_id(),
            data: struct(),
            at: integer()
          }
  end

  defmodule Delete do
    @moduledoc """
    Delete operation.
    """
    defstruct [:operation_id, :data]

    @type t() :: %__MODULE__{
            operation_id: Exshome.DataStream.Operation.operation_id(),
            data: struct()
          }
  end

  defmodule ReplaceAll do
    @moduledoc """
    Operation to replace all previous data.
    """
    @enforce_keys [:data]
    defstruct [:operation_id, :data]

    @type t() :: %__MODULE__{
            operation_id: Exshome.DataStream.Operation.operation_id(),
            data: [struct()]
          }
  end

  defmodule Batch do
    @moduledoc """
    Operation to send a batch of operations.
    """
    @enforce_keys [:operations]
    defstruct [:operations]

    @type allowed_operations() :: Insert.t() | Update.t() | Delete.t() | ReplaceAll.t()

    @type t() :: %__MODULE__{
            operations: [allowed_operations()]
          }
  end

  @type operation_id :: String.t() | nil
  @type t() :: Insert.t() | Update.t() | Delete.t() | ReplaceAll.t() | Batch.t()
  @type single_operation() :: Insert.t() | Update.t() | Delete.t() | ReplaceAll.t()
end
