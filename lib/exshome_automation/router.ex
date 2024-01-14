defmodule ExshomeAutomation.Router do
  @moduledoc """
  Routes for automation application.
  """

  alias ExshomeAutomation.Live

  @key "automation"
  @prefix "/app/#{@key}"

  use Exshome.Behaviours.RouterBehaviour,
    app: ExshomeAutomation,
    key: @key,
    main_path: "#{@prefix}/automations",
    navbar: [
      [
        path: "#{@prefix}/automations",
        name: "automations",
        icon: "hero-command-line-mini",
        extra_views: [Live.AutomationEditor]
      ],
      [
        path: "#{@prefix}/variables",
        name: "variables",
        icon: "hero-variable-mini"
      ]
    ],
    preview: Live.Preview

  scope @prefix do
    live_session ExshomeAutomation, on_mount: [ExshomeWeb.Live.Navigation] do
      live "/automations", Live.Automations
      live "/automations/:id", Live.AutomationEditor
      live "/variables", Live.Variables, :index
      live "/variables/:id", Live.Variables, :show
    end
  end
end
