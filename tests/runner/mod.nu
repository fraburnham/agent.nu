# TODO: document the test runner
#
# It should do simple stuff like be called as the last line of a nu test file and
# run all the `test *` commands (w/o any args for now, maybe test setup stuff soon)

export use stub.nu

export def run [] {
  # Stolen from https://www.nushell.sh/book/testing.html

  print $"\nRunning ($env.CURRENT_FILE) tests...\n"

  let test_commands = (
    scope commands
    | where ($it.type == "custom")
                and ($it.name | str starts-with "test ")
                and not ($it.description | str starts-with "ignore")
    | get name
    | each { |test| [$"print 'Running: ($test)'", $test] }
    | flatten
    | str join "; "
  )

  try {
    nu --commands $"source ($env.CURRENT_FILE); ($test_commands)"
    print $"\n(ansi green_bold)\u{2713}(ansi reset) Tests completed successfully\n"
  } catch {
    print $"\n(ansi red_bold)\u{2717}(ansi reset) Tests in ($env.CURRENT_FILE) failed\n"
  }
}
