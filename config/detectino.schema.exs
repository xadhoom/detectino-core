@moduledoc """
A schema is a keyword list which represents how to map, transform, and validate
configuration values parsed from the .conf file. The following is an explanation of
each key in the schema definition in order of appearance, and how to use them.

## Import

A list of application names (as atoms), which represent apps to load modules from
which you can then reference in your schema definition. This is how you import your
own custom Validator/Transform modules, or general utility modules for use in
validator/transform functions in the schema. For example, if you have an application
`:foo` which contains a custom Transform module, you would add it to your schema like so:

`[ import: [:foo], ..., transforms: ["myapp.some.setting": MyApp.SomeTransform]]`

## Extends

A list of application names (as atoms), which contain schemas that you want to extend
with this schema. By extending a schema, you effectively re-use definitions in the
extended schema. You may also override definitions from the extended schema by redefining them
in the extending schema. You use `:extends` like so:

`[ extends: [:foo], ... ]`

## Mappings

Mappings define how to interpret settings in the .conf when they are translated to
runtime configuration. They also define how the .conf will be generated, things like
documention, @see references, example values, etc.

See the moduledoc for `Conform.Schema.Mapping` for more details.

## Transforms

Transforms are custom functions which are executed to build the value which will be
stored at the path defined by the key. Transforms have access to the current config
state via the `Conform.Conf` module, and can use that to build complex configuration
from a combination of other config values.

See the moduledoc for `Conform.Schema.Transform` for more details and examples.

## Validators

Validators are simple functions which take two arguments, the value to be validated,
and arguments provided to the validator (used only by custom validators). A validator
checks the value, and returns `:ok` if it is valid, `{:warn, message}` if it is valid,
but should be brought to the users attention, or `{:error, message}` if it is invalid.

See the moduledoc for `Conform.Schema.Validator` for more details and examples.
"""
[
  extends: [],
  import: [],
  mappings: [
    "lager.error_logger_redirect": [
      commented: false,
      datatype: :atom,
      default: false,
      doc: "Provide documentation for lager.error_logger_redirect here.",
      hidden: false,
      to: "lager.error_logger_redirect"
    ],
    "lager.crash_log": [
      commented: false,
      datatype: :atom,
      default: false,
      doc: "Provide documentation for lager.crash_log here.",
      hidden: false,
      to: "lager.crash_log"
    ],
    "lager.handlers.Elixir.LagerLogger.level": [
      commented: false,
      datatype: :atom,
      default: :debug,
      doc: "Provide documentation for lager.handlers.Elixir.LagerLogger.level here.",
      hidden: false,
      to: "lager.handlers.Elixir.LagerLogger.level"
    ],
    "guardian.Elixir.Guardian.secret_key": [
      commented: false,
      datatype: :binary,
      default: "changemeabsolutelyyaddayadda",
      doc: "Provide documentation for guardian.Elixir.Guardian.secret_key here.",
      hidden: false,
      to: "guardian.Elixir.Guardian.secret_key"
    ],
    "logger.level": [
      commented: false,
      datatype: :atom,
      default: :info,
      doc: "Provide documentation for logger.level here.",
      hidden: false,
      to: "logger.level"
    ],
    "detectino.can_interface": [
      commented: false,
      datatype: :binary,
      default: "can0",
      doc: "Provide documentation for detectino.can_interface here.",
      hidden: false,
      to: "detectino.can_interface"
    ],
    "detectino.Elixir.DtWeb.Endpoint.http.port": [
      commented: false,
      datatype: :integer,
      default: 8888,
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.http.port here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Endpoint.http.port"
    ],
    "detectino.Elixir.DtWeb.Endpoint.url.host": [
      commented: false,
      datatype: :binary,
      default: "example.com",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.url.host here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Endpoint.url.host"
    ],
    "detectino.Elixir.DtWeb.Endpoint.secret_key_base": [
      commented: false,
      datatype: :binary,
      default: "CHANGEME",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.secret_key_base here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Endpoint.secret_key_base"
    ],
    "detectino.Elixir.DtWeb.Repo.username": [
      commented: false,
      datatype: :binary,
      default: "postgres",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Repo.username here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Repo.username"
    ],
    "detectino.Elixir.DtWeb.Repo.password": [
      commented: false,
      datatype: :binary,
      default: "postgres",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Repo.password here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Repo.password"
    ],
    "detectino.Elixir.DtWeb.Repo.database": [
      commented: false,
      datatype: :binary,
      default: "dt_web_prod",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Repo.database here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Repo.database"
    ],
    "detectino.Elixir.DtWeb.Repo.pool_size": [
      commented: false,
      datatype: :integer,
      default: 20,
      doc: "Provide documentation for detectino.Elixir.DtWeb.Repo.pool_size here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Repo.pool_size"
    ]
  ],
  transforms: [],
  validators: []
]
