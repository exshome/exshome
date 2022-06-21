[
  import_deps: [:phoenix],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs}", "bin/*"],
  plugins: [Phoenix.LiveView.HTMLFormatter]
]
