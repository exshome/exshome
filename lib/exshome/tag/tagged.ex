defprotocol Exshome.Tag.Tagged do
  @moduledoc """
  Protocol to mark a module as tagged.
  """

  @spec tags(t()) :: [atom()]
  def tags(data)
end
