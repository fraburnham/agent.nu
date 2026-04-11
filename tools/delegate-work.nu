# use ../agent-loop.nu
# use utils.nu

# export def "delegate work" [
#   params: record<worker: string, task: string>
#   #reply_to_job_id: int
# ]: nothing -> int {
#   # I need to know the tool handler id
#   job spawn --tag "delegatation-controller" { ||
#     let agent_job_id = agent-loop run (tui run) $params.worker

#     $params.task
#     | job send $agent_job_id
  
#     loop {
#       match (job recv) {
#         $context => {
#           print ($context)
#           # ^^ use that to get the current final response
#           # Once I have an assistant repsponse w/o tool use the delegation is done
#         }
#       }
#     }
#   }
# }

export def "delegate work" [
  params: record<worker: string, task: string>
]: nothing -> string {
  "The most popular lexer is logos. It is fast and simple."
}

# Have the web-researcher determine what the most popular lexer is for new programming languages whose first compiler is written in rust.
