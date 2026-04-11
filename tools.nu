use tools/utils.nu

export use tools/definitions.nu [tool_schemas]
export use tools/utils.nu ["handle agent use"]

export def "available to agent" [
  agent: string
] {
  utils available to agent $tool_schemas $agent
}
