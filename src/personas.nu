# TODO: docs

const defaults = {
  tools: []
  delegatable: false
}

export def "system prompt" [
  config: record
  persona: string
] {
  open --raw ($"($config.personas_path)/($persona)/PERSONA.md" | path expand)
}

export def config [
  config: record
  persona: string
] {
  open ($"($config.personas_path)/($persona)/persona.json" | path expand)
}

export def model [
  config: record
  persona: string
] {
  config $config $persona
  | get model
}
