use ../personas.nu
use bedrock.nu
use ollama.nu

export def chat [
  config: record
  persona: string
]: record -> record { # context in -> response message out
  let input = $in

  match ($config.provider) {
    "ollama" => {
      $input
      | ollama chat $config $persona
    }

    "bedrock" => {
      $input
      | bedrock chat $config $persona
    }
  }
}
