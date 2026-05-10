use ../personas.nu
use ../tools.nu

export def initial [
  config: record
  persona: string
]: nothing -> record {
  {
    messages: [{
      role: "system"
      content: (personas system prompt $config $persona)
    }]
    tools: (tools available to persona $config $persona)
  }
}
