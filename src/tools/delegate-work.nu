use ../agent-loop.nu
use utils.nu
use ../context

export def main [
  config: record
  tool_handler_job_id: int
  params: record<worker: string, task: string>
]: nothing -> string {
  mut message = {}

  agent-loop run $config (job id) $tool_handler_job_id (
    context initial $config $params.worker
    | context append prompt $params.task
  )

  loop {
    $message = job recv
    # TODO: add timeout (configurable per agent type?) to manage llms in loops
    #       if it times out w/o a message assume something is broken
    #       The timeout will have to be long enough to include _loading_ the model, so maybe an intelligent thing can know
    #       if the model is loaded before it "starts" the timer...

    let last_response_from_context = $message.context.messages
    | last

    if ($last_response_from_context.tool_calls? | is-empty) and ($last_response_from_context.role? == "assistant") {
      break
    } else {
      $message
      | job send $message.reply_to_job_id
    }
  }

  $message.context.messages
  | last
  | get content
}

