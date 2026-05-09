use context/manage.nu

def run-tool [
  tool_path: string
  config: record
  tool_call: record
] {
  if not ($tool_path | path exists) {
    "No matching tool found. Retrying the call will not help."
  } else {
    {
      config: $config
      tool_call: $tool_call
    }
    | to json
    | run-external ($"($config.tools_path)/($tool_call.function.name)/run" | path expand)
    | complete
    | do {
      let result = $in

      if $result.exit_code == 0 {
        $result.stdout
      } else {
        ["TOOL USE FAILED! Failure output follows:" $result.stdout $result.stderr]
        | str join "\n"
      }
    }
  }
}

export def "handle calls" [
  config: record
] { # context in -> tool responses (or empty list) out
  let context: record = $in
  let tool_calls = $context.messages
  | last
  | get tool_calls?
  | default []

  $tool_calls
  | each { |tool_call|
    {
      id: $tool_call.id?
      role: "tool"
      content: (run-tool $"($config.tools_path)/($tool_call.function.name)/run" $config  $tool_call)
    }
  }
}

export def "available to persona" [
  config: record
  persona: string
] {
  personas config $config $persona
  | get tools
  | each { |tool_name|
    open ($"($config.tools_path)/($tool_name)/definition.json" | path expand)
  }
}
