export def "append message" [
  context: record
]: record<role: string> -> record { # raw message/response in -> context out
  let response: record = $in

  $context
  | upsert messages { |context|
    $context.messages
    | append $response
  }
}

