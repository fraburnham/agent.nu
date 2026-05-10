export def "history set path" [
  persona: string
  --tool-call-id: string
]: record -> record { # config in -> config out
  $in
  | update history_path { |config|
    # If the path has an extension then use the dir it is in instead
    let base = if ($config.history_path | str ends-with ".jsonl") {
      $config.history_path
      | path dirname
    } else {
      $config.history_path
    }

    # if there is tool-call-id use that, else use timestamp method
    if ($tool_call_id | is-not-empty) {
      $"($base)/($tool_call_id)/($persona)/session.jsonl"
    } else {
      let timestamp = date now
      | format date "%Y-%m-%dT%H:%M:%S%Z"

      $"($base)/($timestamp)/($persona)/session.jsonl"
    }
  }
}

export def "history start-worker" [
  history_path: string
]: nothing -> int {
  mkdir ($history_path | path dirname)

  job spawn --description history-worker { ||
    loop {
      job recv
      | to json --raw
      | do { $"($in)\n" }
      | save --append $history_path
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

