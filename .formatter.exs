# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 80,
  locals_without_parens: [plug: 1, plug: 2],
  export: [
    locals_without_parens: [plug: 1, plug: 2]
  ],
  pipeline: [
    force_newline: true
  ]
]
