defmodule Exshome.Repo do
  use Ecto.Repo,
    otp_app: :exshome,
    adapter: Ecto.Adapters.SQLite3
end
