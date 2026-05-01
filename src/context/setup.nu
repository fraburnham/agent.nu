use ../personas.nu
use ../tools/utils.nu

export def initial [
  config: record
  persona: string
] {
  {
    messages: [{
      role: "system"
      content: (personas system prompt $config $persona)
    }]
    tools: (utils available to persona $config $persona)
  }
}
