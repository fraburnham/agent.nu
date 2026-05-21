use ../context
use ../personas.nu

def function-arguments-updater [
  closure: closure
]: record -> record {
  update tool_calls { |r|
    $r.tool_calls
    | each { |tc|
      $tc
      | update function.arguments $closure
    }
  }
}

def tool-arguments-to-json []: record -> record {
  update messages { |request|
    $request.messages
    | each { |message|
      if ($message.tool_calls? | is-not-empty) {
        $message
        | function-arguments-updater { |tc|
          $tc.function.arguments
          | to json --raw
        }
      } else {
        $message
      }
    }
  }
}

def tool-arguments-from-json []: record -> record {
  let message = $in
  if ($message.tool_calls? | is-not-empty) {
    $message
    | function-arguments-updater { |tc|
      $tc.function.arguments
      | from json
    }
  } else {
    $message
  }
}


def parse-aws-cli-response []: record -> record {
  let result = $in

  do {
    if ($result.exit_code != 0) {
      print -e $result
      error make { msg: "Failed to call bedrock" }
    }

    $result
  }
  | get stderr
  | from json
}

export def chat [
  config: record
  persona: string
]: record -> record { # context in -> response message out
  let request = $in
  | tool-arguments-to-json
  | to json --raw
  | base64

  let model_id = personas model $config $persona

  ^aws bedrock-runtime invoke-model --model-id $model_id --body $request --output json /dev/stderr
  | complete
  | parse-aws-cli-response
  | get choices.0.message
  | tool-arguments-from-json
}
