use context
use personas.nu

export def chat [
  config: record
  persona: string
]: record -> record {
  let context = $in
  | insert model (personas model $config $persona)
  | insert stream false

  $context
  | to json
  | http post $"($config.ollama_host)/api/chat"
  | get message
  | context append response ($context | reject model stream)
}
