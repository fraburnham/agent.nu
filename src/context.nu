use tools/definitions.nu [tool_schemas]
use context/setup.nu ["initial"]

alias _initial = initial

export def initial [
  agent: string
] {
  _initial $tool_schemas $agent
}
