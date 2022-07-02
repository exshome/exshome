# Changelog

## v0.2.0
  * Moved GenServerDependencySupervisor to own file.
  * Created GenServerDependency hooks.
  * Removed parse_opts/1 callback from GenServerDependency.
  * Added system-wide registry.
  * Added ExshomeDependency.dependency_module/1 function.
  * Use SystemRegistry for TestRegistry.
  * Add default timeout to the GenServerDependency call function. Running tests with a `--trace` flag will allow you to debug your code without interruptions.
  * Allow to set value for all variables.
  * Add support for readonly variables.
  * Implemented `Exshome.Variable.list/0` function.
  * Added VariableRegistry for automation.

## v0.1.7 (2022-06-28)
  * Created database if it does not exist before migraions.

## v0.1.6 (2022-06-28)
  * Fixed manual track deletion.
  * Created simple automation app.
  * Allow to set secret_key_base and signing_salt via env variables.
  * Run migrations before starting the app via launcher.

## v0.1.5 (2022-06-24)
  * Added ability to start launcher script with IEx via `System.no_halt/1`.
  * Stop the launcher if application crashes.
  * Added installation guide for a Single Board Computer (SBC).

## v0.1.4 (2022-06-22)
  * Use timezone database in launcher script.
  * Do not start MPV server if MPV is not installed.

## v0.1.3 (2022-06-21)
  * Add simple launcher script.
  * Setup github action to release the application.

## v0.1.2 (2022-06-21)
  * Add migration scripts.

## v0.1.1 (2022-06-20)
  * Update package configuration.

## v0.1.0 (2022-06-19)
  * Simple player.
  * Added docs generation.
