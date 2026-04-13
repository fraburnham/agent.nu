export use prompt.nu
export use response.nu

export def header []: nothing -> nothing {
  print ""
  print $"(ansi bo)Type '/exit' to quit(ansi reset)"
}

def handle [
  prompt_job_id: int
]: record -> nothing {
  let message = $in
  let context = $in.context

  if (response $context) or (($context.messages? | length) == 1) {
    {
      type: "ready-for-input"
      reply_to_job_id: $message.reply_to_job_id
    }
    | job send $prompt_job_id
  }
}

export def run []: nothing -> int {
  job spawn --description tui { ||
    let prompt_job_id = prompt

    header

    loop {
      job recv
      | handle $prompt_job_id
    }
  }
}
