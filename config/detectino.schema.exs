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
      hidden: true,
      to: "lager.error_logger_redirect"
    ],
    "lager.error_logger_whitelist": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        Logger.ErrorHandler
      ],
      doc: "Provide documentation for lager.error_logger_whitelist here.",
      hidden: true,
      to: "lager.error_logger_whitelist"
    ],
    "lager.crash_log": [
      commented: false,
      datatype: :atom,
      default: false,
      doc: "Provide documentation for lager.crash_log here.",
      hidden: true,
      to: "lager.crash_log"
    ],
    "lager.handlers.Elixir.LagerLogger.level": [
      commented: false,
      datatype: :atom,
      default: :debug,
      doc: "Provide documentation for lager.handlers.Elixir.LagerLogger.level here.",
      hidden: true,
      to: "lager.handlers.Elixir.LagerLogger.level"
    ],
    "plug.statuses": [
      commented: false,
      datatype: :binary,
      doc: "Provide documentation for plug.statuses here.",
      hidden: true,
      to: "plug.statuses"
    ],
    "guardian.Elixir.Guardian.issuer": [
      commented: false,
      datatype: :binary,
      default: "DtWeb",
      doc: "Provide documentation for guardian.Elixir.Guardian.issuer here.",
      hidden: true,
      to: "guardian.Elixir.Guardian.issuer"
    ],
    "guardian.Elixir.Guardian.ttl": [
      commented: false,
      datatype: :integer,
      default: 86400,
      doc: "Provide documentation for guardian.Elixir.Guardian.ttl here.",
      hidden: false,
      to: "guardian.Elixir.Guardian.ttl"
    ],
    "guardian.Elixir.Guardian.verify_issuer": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for guardian.Elixir.Guardian.verify_issuer here.",
      hidden: true,
      to: "guardian.Elixir.Guardian.verify_issuer"
    ],
    "guardian.Elixir.Guardian.secret_key": [
      commented: false,
      datatype: :binary,
      default: "changemeabsolutelyyaddayadda",
      doc: "Provide documentation for guardian.Elixir.Guardian.secret_key here.",
      hidden: false,
      to: "guardian.Elixir.Guardian.secret_key"
    ],
    "guardian.Elixir.Guardian.serializer": [
      commented: false,
      datatype: :atom,
      default: DtWeb.GuardianSerializer,
      doc: "Provide documentation for guardian.Elixir.Guardian.serializer here.",
      hidden: true,
      to: "guardian.Elixir.Guardian.serializer"
    ],
    "guardian.Elixir.Guardian.hooks": [
      commented: false,
      datatype: :atom,
      default: DtWeb.GuardianHooks,
      doc: "Provide documentation for guardian.Elixir.Guardian.hooks here.",
      hidden: true,
      to: "guardian.Elixir.Guardian.hooks"
    ],
    "logger.console.format": [
      commented: false,
      datatype: :binary,
      default: """
      $time $metadata[$level] $message
      """,
      doc: "Provide documentation for logger.console.format here.",
      hidden: true,
      to: "logger.console.format"
    ],
    "logger.console.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :request_id
      ],
      doc: "Provide documentation for logger.console.metadata here.",
      hidden: true,
      to: "logger.console.metadata"
    ],
    "logger.level": [
      commented: false,
      datatype: :atom,
      default: :info,
      doc: "Provide documentation for logger.level here.",
      hidden: false,
      to: "logger.level"
    ],
    "logger.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :pid
      ],
      doc: "Provide documentation for logger.metadata here.",
      hidden: true,
      to: "logger.metadata"
    ],
    "phoenix.generators.migration": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for phoenix.generators.migration here.",
      hidden: true,
      to: "phoenix.generators.migration"
    ],
    "phoenix.generators.binary_id": [
      commented: false,
      datatype: :atom,
      default: false,
      doc: "Provide documentation for phoenix.generators.binary_id here.",
      hidden: true,
      to: "phoenix.generators.binary_id"
    ],
    "phoenix.serve_endpoints": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for phoenix.serve_endpoints here.",
      hidden: true,
      to: "phoenix.serve_endpoints"
    ],
    "detectino.Elixir.DtCore.Output.Actions.Email.alarm_subjects": [
      commented: false,
      datatype: :binary,
      doc: "Provide documentation for detectino.Elixir.DtCore.Output.Actions.Email.alarm_subjects here.",
      hidden: false,
      to: "detectino.Elixir.DtCore.Output.Actions.Email.alarm_subjects"
    ],
    "detectino.Elixir.DtCore.Output.Actions.Email.delayed_alarm_subjects": [
      commented: false,
      datatype: :binary,
      doc: "Provide documentation for detectino.Elixir.DtCore.Output.Actions.Email.delayed_alarm_subjects here.",
      hidden: false,
      to: "detectino.Elixir.DtCore.Output.Actions.Email.delayed_alarm_subjects"
    ],
    "detectino.environment": [
      commented: false,
      datatype: :atom,
      default: :prod,
      doc: "Provide documentation for detectino.environment here.",
      hidden: true,
      to: "detectino.environment"
    ],
    "detectino.Elixir.DtCore.Output.Actions.Email.Mailer.adapter": [
      commented: false,
      datatype: :atom,
      default: Swoosh.Adapters.STMP,
      doc: "Provide documentation for detectino.Elixir.DtCore.Output.Actions.Email.Mailer.adapter here.",
      hidden: true,
      to: "detectino.Elixir.DtCore.Output.Actions.Email.Mailer.adapter"
    ],
    "detectino.can_interface": [
      commented: false,
      datatype: :binary,
      default: "can0",
      doc: "Provide documentation for detectino.can_interface here.",
      hidden: false,
      to: "detectino.can_interface"
    ],
    "detectino.Elixir.DtWeb.Endpoint.url.host": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.url.host here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Endpoint.url.host"
    ],
    "detectino.Elixir.DtWeb.Endpoint.render_errors.accepts": [
      commented: false,
      datatype: [
        list: :binary
      ],
      default: [
        "html",
        "json"
      ],
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.render_errors.accepts here.",
      hidden: true,
      to: "detectino.Elixir.DtWeb.Endpoint.render_errors.accepts"
    ],
    "detectino.Elixir.DtWeb.Endpoint.pubsub.name": [
      commented: false,
      datatype: :atom,
      default: DtWeb.PubSub,
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.pubsub.name here.",
      hidden: true,
      to: "detectino.Elixir.DtWeb.Endpoint.pubsub.name"
    ],
    "detectino.Elixir.DtWeb.Endpoint.pubsub.adapter": [
      commented: false,
      datatype: :atom,
      default: Phoenix.PubSub.PG2,
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.pubsub.adapter here.",
      hidden: true,
      to: "detectino.Elixir.DtWeb.Endpoint.pubsub.adapter"
    ],
    "detectino.Elixir.DtWeb.Endpoint.http.port": [
      commented: false,
      datatype: :integer,
      default: 8888,
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.http.port here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Endpoint.http.port"
    ],
    "detectino.Elixir.DtWeb.Endpoint.root": [
      commented: false,
      datatype: :binary,
      default: ".",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.root here.",
      hidden: true,
      to: "detectino.Elixir.DtWeb.Endpoint.root"
    ],
    "detectino.Elixir.DtWeb.Endpoint.server": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.server here.",
      hidden: true,
      to: "detectino.Elixir.DtWeb.Endpoint.server"
    ],
    "detectino.Elixir.DtWeb.Endpoint.version": [
      commented: false,
      datatype: :binary,
      default: "0.0.1",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.version here.",
      hidden: true,
      to: "detectino.Elixir.DtWeb.Endpoint.version"
    ],
    "detectino.Elixir.DtWeb.Endpoint.secret_key_base": [
      commented: false,
      datatype: :binary,
      default: "vPgQSPv6YsGQBqrPS8hV1I4xUqQHI3V8",
      doc: "Provide documentation for detectino.Elixir.DtWeb.Endpoint.secret_key_base here.",
      hidden: false,
      to: "detectino.Elixir.DtWeb.Endpoint.secret_key_base"
    ],
    "detectino.Elixir.DtCtx.Repo.adapter": [
      commented: false,
      datatype: :atom,
      default: Ecto.Adapters.Postgres,
      doc: "Provide documentation for detectino.Elixir.DtCtx.Repo.adapter here.",
      hidden: true,
      to: "detectino.Elixir.DtCtx.Repo.adapter"
    ],
    "detectino.Elixir.DtCtx.Repo.username": [
      commented: false,
      datatype: :binary,
      default: "postgres",
      doc: "Provide documentation for detectino.Elixir.DtCtx.Repo.username here.",
      hidden: false,
      to: "detectino.Elixir.DtCtx.Repo.username"
    ],
    "detectino.Elixir.DtCtx.Repo.password": [
      commented: false,
      datatype: :binary,
      default: "postgres",
      doc: "Provide documentation for detectino.Elixir.DtCtx.Repo.password here.",
      hidden: false,
      to: "detectino.Elixir.DtCtx.Repo.password"
    ],
    "detectino.Elixir.DtCtx.Repo.database": [
      commented: false,
      datatype: :binary,
      default: "dt_web_prod",
      doc: "Provide documentation for detectino.Elixir.DtCtx.Repo.database here.",
      hidden: false,
      to: "detectino.Elixir.DtCtx.Repo.database"
    ],
    "detectino.Elixir.DtCtx.Repo.pool_size": [
      commented: false,
      datatype: :integer,
      default: 20,
      doc: "Provide documentation for detectino.Elixir.DtCtx.Repo.pool_size here.",
      hidden: false,
      to: "detectino.Elixir.DtCtx.Repo.pool_size"
    ],
    "detectino.Elixir.DtCtx.Repo.hostname": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "Provide documentation for detectino.Elixir.DtCtx.Repo.hostname here.",
      hidden: false,
      to: "detectino.Elixir.DtCtx.Repo.hostname"
    ]
  ],
  transforms: [
    "guardian.Elixir.Guardian.ttl": fn(conf) ->
      [{k, v}] = Conform.Conf.get(conf, "guardian.Elixir.Guardian.ttl")
      {v, :seconds}
    end
  ],
  validators: []
]
