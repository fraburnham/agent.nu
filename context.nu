export def "append prompt" [
  prompt: string
]: record -> record {
  $in
  | upsert messages { |context|
    $context.messages
    | append {
      role: "user"
      content: $prompt
    }
  }
}

export def "append response" [
  context: record
]: record<role: string, content: string, thinking: string> -> record {
  let response = $in

  $context
  | upsert messages { |context|
    $context.messages
    | append $response
  }
}
