defmodule Exshome.DataStream.Operation do
  @moduledoc """
  Contains DataStream Operations.
  """

  defmodule Insert do
    @moduledoc """
    Insert operation.
    """
    defstruct [:data, at: -1]

    @type t() :: %__MODULE__{
            data: struct(),
            at: integer()
          }
  end

  defmodule Update do
    @moduledoc """
    Update operation.
    """
    defstruct [:data, at: -1]

    @type t() :: %__MODULE__{
            data: struct(),
            at: integer()
          }
  end

  defmodule Delete do
    @moduledoc """
    Delete operation.
    """
    defstruct [:data]

    @type t() :: %__MODULE__{
            data: struct()
          }
  end

  defmodule Batch do
    @moduledoc """
    Operation to send a batch of operations.
    """
    @enforce_keys [:operations]
    defstruct [:operations]

    @type allowed_operations() :: Insert.t() | Update.t() | Delete.t()

    @type t() :: %__MODULE__{
            operations: [allowed_operations()]
          }
  end

  @type t() :: Insert.t() | Update.t() | Delete.t() | Batch.t()
  @type single_operation() :: Insert.t() | Update.t() | Delete.t()
end
