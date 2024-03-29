defmodule ExshomeWebTest.ErrorHTMLTest do
  use ExshomeWebTest.ConnCase, async: true

  test "renders 404.html" do
    assert ExshomeWeb.ErrorHTML.render("404.html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert ExshomeWeb.ErrorHTML.render("500.html", []) == "Internal Server Error"
  end
end
