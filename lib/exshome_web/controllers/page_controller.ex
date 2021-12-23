defmodule ExshomeWeb.PageController do
  use ExshomeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
