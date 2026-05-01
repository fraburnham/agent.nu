use api.nu
use history.nu
use context
use tools.nu
use personas.nu

def advance [
  config: record
  persona: string
  history_worker_id: int
  tool_handler_job_id: int
]: record -> record {
  api chat $config $persona
  | tools run $tool_handler_job_id
  | history update $history_worker_id
}

export def run [
  config: record
  persona: string
  manager_job_id: int
  tool_handler_job_id: int
  initial_context: record
  --model: string = "qwen3.5:0.8b-bf16" #"gpt-oss:20b" #"gemma4:e2b" #"qwen3.5:9b" #"qwen3.5:9b-bf16"
] {
  job spawn --description agent-loop { ||
    # TODO: token use tracking (iirc ollama is responding with all kinds of metrics, use them to track context fullness)
    # TODO: config file to pull model and params (temp/top_p/context length/etc) from

    let history_worker_id = history start worker # TODO: this needs to be cleaned up or it'll be a leak (so probabably have the manager start it...)
    mut context: record = $initial_context
  
    loop {
      # TODO: I think this could drop the mutable if the non-context events pass a context...
      # Send the manager the current/advanced context
      {
        context: $context
        reply_to_job_id: (job id)
        type: context
      }
      | job send $manager_job_id

      let message = job recv

      $context = match $message.type {
        "user-input" => {
          match ($message.user_input) {
            # TODO: /clear
            # TODO: /context-remove-latest-response
            # TODO: /context-remove-latest-prompt
            "/exit" => { # So now the agent loop has to handle these again?
              "/exit"
              | job send 0

              break
            }

            $user_input => {
              $context
              | context append prompt $message.user_input
            }
          }
        }

        "context" => {
          $message.context
        }

        _ => {
          # TODO: use logging and log levels and whatever config to hide debug logs most of the time
          print "Ignoring message"
          print $message
          $context
        }
      }
      | advance $config $persona $history_worker_id $tool_handler_job_id
    }
  }
}
