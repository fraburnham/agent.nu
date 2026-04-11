export def "append prompt" [
  prompt: oneof<string, nothing>
]: record -> record {
  let context = $in

  if ($prompt | is-not-empty) {
    $context
    | upsert messages { |context|
      $context.messages
      | append {
        role: "user"
        content: $prompt
      }
    }
  } else {
    $context
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
