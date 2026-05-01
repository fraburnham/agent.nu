use setup.nu ["initial"]

export use manage.nu *

alias _initial = initial

# This seems like pointless indirection now...
export def initial [
  config: record
  agent: string
] {
  _initial $config $agent
}
