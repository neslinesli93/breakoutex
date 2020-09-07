[
  import_deps: [:phoenix],
  inputs: ["*.{ex,exs}", "{config,lib,priv,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"],
  line_length: 120,
  locals_without_parens: [
    # plug
    plug: :*,
    parse: :*,
    serialize: :*,
    value: :*,
    match: :*,

    # phoenix
    transport: :*,
    socket: :*,
    pipe_through: :*,
    forward: :*,
    options: :*,
    defenum: :*,
    get: :*,
    post: :*,
    delete: :*,
    patch: :*,
    head: :*
  ]
]
