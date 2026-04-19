# TODO: docs (esp stuff like config properties and their uses)

export const defaults = {
  base_persona: "high-level-leader"
  personas_path: "~/.agent.nu/personas"
  # ollama_host: "https://workload.api.llm.skynet" # fail if missing

  # The persona -> model mapping should be with the persona files, yeah? (also other configs like temp etc)
  # Mmm. And the personas will need the description type info that is used to build up the
  # workers for delegate-work. And a flag to indicate if the persona can be delegated to.
  # And a list of tools that the persona has access to (the rest of the tool info should be
  # fetched at persona launch time)
}

export def load [
  config_file: string
]: nothing -> record<base_persona: string, personas_path: string, ollama_host: string> {
  # If passing the config ends up silly I could read the config to sqlite and then pull data from there

  let config = $defaults
  | merge deep (open ($config_file | path expand))

  if ($config.ollama_host | is-empty) {
    error make { msg: "`ollama_host` is a required config property" }
  }

  return $config
}
