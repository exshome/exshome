defmodule Exshome.DataStream.Operation do
  @moduledoc """
  Contains DataStream Operations.
  """

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

  @type t() :: Insert.t() | Update.t() | Delete.t()
end
