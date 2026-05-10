# TODO: docs (esp stuff like config properties and their uses)

const defaults = {
  base_persona: "high-level-leader"
  personas_path: "./personas"
  tools_path: "./tools"
  history_path: "./.agent.nu/history"
}

export def load [
  config_file: string
]: nothing -> record<base_persona: string, personas_path: string, ollama_host: string, history_path: string> {
  # If passing the config ends up silly I could read the config to sqlite and then pull data from there

  let config = $defaults
  | merge deep (open ($config_file | path expand))

  if ($config.ollama_host | is-empty) {
    error make { msg: "`ollama_host` is a required config property" }
  }

  return $config
}
