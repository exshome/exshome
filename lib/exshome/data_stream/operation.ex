defmodule Exshome.DataStream.Operation do
  @moduledoc """
  Contains DataStream Operations.
  """

  defmodule ReplaceAll do
    @moduledoc """
    Operation to replace all previous data.
    """
    @enforce_keys [:data]
    defstruct [:data]

    @type t() :: %__MODULE__{
            data: [struct()]
          }
  end

  defmodule Insert do
    @moduledoc """
    Insert operation.
    """
    @enforce_keys [:id]
    defstruct [:id, :data]

    @type t() :: %__MODULE__{
            id: String.t(),
            data: struct()
          }
  end

  defmodule Update do
    @moduledoc """
    Update operation.
    """
    @enforce_keys [:id]
    defstruct [:id, :data]

    @type t() :: %__MODULE__{
            id: String.t(),
            data: struct()
          }
  end

  defmodule Delete do
    @moduledoc """
    Delete operation.
    """
    @enforce_keys [:id]
    defstruct [:id, :data]

    @type t() :: %__MODULE__{
            id: String.t(),
            data: struct()
          }
  end

  defmodule Batch do
    @moduledoc """
    Operation to send a batch of operations.
    """
    @enforce_keys [:operations]
    defstruct [:operations]

    @type allowed_operations() :: ReplaceAll.t() | Insert.t() | Update.t() | Delete.t()

    @type t() :: %__MODULE__{
            operations: [allowed_operations()]
          }
  end

  @type t() :: Insert.t() | Update.t() | Delete.t() | ReplaceAll.t() | Batch.t()
end
