use ../tools/definitions.nu [tool_schemas]
use setup.nu ["initial"]

export use manage.nu *

alias _initial = initial

export def initial [
  agent: string
] {
  _initial $tool_schemas $agent
}
