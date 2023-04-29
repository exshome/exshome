defmodule ExshomePlayer.Web.View do
  @moduledoc """
  View module for Player app.
  """

  use ExshomeWeb, :html

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"
end
