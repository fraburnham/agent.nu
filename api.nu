use context.nu

export def chat [
  # TODO: adjust ts mode to handle indentation for <\netc:...\n>
  context: record<messages: table<role: string, content: string>>
  prompt: string
  --model: string
  --host: string
]: nothing -> record {
  let context = $context
  | insert model $model
  | insert stream false
  | context append prompt $prompt

  $context
  | to json
  | http post $"($host)/api/chat"
  | get message
  | context append response ($context | reject model stream)
}
