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
]: record -> record {
  let response: record = $in

  $context
  | upsert messages { |context|
    $context.messages
    | append $response
  }
}
