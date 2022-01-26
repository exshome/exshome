defmodule Exshome.Repo do
  use Ecto.Repo,
    otp_app: :exshome,
    adapter: Ecto.Adapters.SQLite3

  @hook_module Application.compile_env(:exshome, :repo_hook_module)
  if @hook_module do
    defoverridable(get_dynamic_repo: 0, put_dynamic_repo: 1)

    def get_dynamic_repo do
      if @hook_module.tests_started?(), do: @hook_module.get_dynamic_repo(), else: super()
    end

    def put_dynamic_repo(repo) do
      if @hook_module.tests_started?(), do: @hook_module.put_dynamic_repo(repo), else: super(repo)
    end
  end
end
