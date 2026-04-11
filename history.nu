export def "start worker" []: nothing -> int {
  let timestamp = date now
  | format date "%Y-%m-%dT%H:%M:%S%Z"

  mkdir .agent.nu/history

  job spawn --tag history-worker { ||
    loop {
      # TODO: append instead of clobber or something (probably use a more appendable format...)
      job recv
      | save -f $".agent.nu/history/($timestamp).json"
    }
  }
}

export def update [
  history_worker_id: int
]: record -> record {
  let context = $in

  $context
  | job send $history_worker_id

  $context
}
