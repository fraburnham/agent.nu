use context.nu

export def chat [
  --model: string
  --host: string
]: record -> record {
  let context = $in
  | insert model $model
  | insert stream false

  $context
  | to json
  | http post $"($host)/api/chat"
  | get message
  | context append response ($context | reject model stream)
}
