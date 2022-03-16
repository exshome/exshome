defmodule ExshomeWeb.SettingsComponentView do
  use ExshomeWeb, :view

  def render_field(form, field, data) when is_atom(field) do
    select(form, field, data[:allowed_values].(), class: "dark:bg-black rounded-lg")
  end
end