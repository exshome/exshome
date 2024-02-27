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

  scope @prefix, Live do
    live_session ExshomeAutomation, on_mount: [ExshomeWeb.Live.Navigation] do
      live "/automations", Automations
      live "/automations/:id", AutomationEditor
      live "/variables", Variables, :index
      live "/variables/:id", Variables, :show
    end
  end
end
