use ../personas.nu [personas]
use ../tools/utils.nu

export def initial [
  tool_schemas: record
  agent: string
] {
  {
    messages: [{
      role: "system"
      content: ($personas | get $agent)
    }]
    tools: (utils available to agent $tool_schemas $agent)
  }
}
