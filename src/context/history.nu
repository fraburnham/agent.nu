export def "history start-worker" []: nothing -> int {
  let timestamp = date now
  | format date "%Y-%m-%dT%H:%M:%S%Z"

  # TODO: get this info from the manager who will base it on config details
  mkdir .agent.nu/history

  # OK! Tool call responses aren't being properly captured by this method.

  # TODO: decouple this from the _shape_ of the context. The caller will have the most recent message available to them so they can pass it here.
  job spawn --description history-worker { ||
    loop {
      job recv
      | to json --raw
      | do { $"($in)\n" }
      | save --append $".agent.nu/history/($timestamp).jsonl"
    }
  }
}

export def "history update" [
  history_worker_id: int
]: record -> record {
  let message = $in

  $message
  | job send $history_worker_id

  $message
}

# TODO: move this into context and hook the `append *` fns up to send messages to it (will probably require passing more data about the agent around in messages)
