use std/log

use api.nu
use context
use tools.nu
use personas.nu

def advance [
  config: record
  persona: string
  history_worker_id: int
]: record -> record {
  let $context = $in

  $context
  | api chat $config $persona
  | context history update $history_worker_id
  | context append message $context
  | do {
    # Use tools
    let context = $in

    $context
    | tools handle calls $config
    | reduce --fold $context { |tool_response, c|
      $tool_response
      | context history update $history_worker_id
      | context append message $c
    }
  }
}

export def run [
  config: record
  persona: string
  manager_job_id: int
  initial_context: record
] {
  job spawn --description agent-loop { ||
    # TODO: token use tracking (iirc ollama is responding with all kinds of metrics, use them to track context fullness)
    # TODO: config file to pull model and params (temp/top_p/context length/etc) from

    mut context: record = $initial_context
    let history_worker_id = context history start-worker

    $initial_context.messages
    | each { |message|
      context history update $history_worker_id
    }
  
    loop {
      # TODO: There's probably a way to drop the mutable context...
      # Send the manager the current/advanced context (so it can be displayed/evaluated)
      {
        context: $context
        reply_to_job_id: (job id)
        type: context
      }
      | job send $manager_job_id
      # Hmm! I'm missing the tool use stuff now... Because more than one _thing_ can happen before the controller gets a message
      # So how does _it_ know to handle stuff in isolation? That means it should get the same message as the history worker and at the same time?
      # Oh no. It got the message but it got it _after_ the tool use. I see. Ok. I do think I want to send just the role messages to the controller
      # All the advancing can be handled in here, I think...

      # The message for this turn is
      # 1. User input
      # 2. Tool use that the model needs to be advanced so the model sees it
      # 3. A non-terminal output from the model that needs to be advanced
      let message = match ($context | context get state) {
        "awaiting-controller-input" => {
          job recv
        }

        _ => {
          {
            context: $context
            reply_to_job_id: (job id)
            type: context
          }
        }
      }

      # Advance the context
      $context = match $message.type {
        "user-input" => {
          match ($message.user_input.content) {
            # TODO: /clear
            # TODO: /context-remove-latest-response
            # TODO: /context-remove-latest-prompt
            "/exit" => {
              job kill $history_worker_id

              "/exit"
              | job send 0

              break
            }

            _ => {
              $message.user_input
              | context history update $history_worker_id
              | context append message $context
            }
          }
        }

        "context" => {
          # Keep advancing the context
          $message.context
        }
      }
      | advance $config $persona $history_worker_id
    }
  }
}

