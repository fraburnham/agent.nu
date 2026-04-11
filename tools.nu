use tools/definitions.nu [tool_schemas]
use tools/utils.nu

export use tools/utils.nu ["handle agent use"]

export def "available to agent" [
  persona: string
] {
  utils available to agent $tool_schemas $persona
}
