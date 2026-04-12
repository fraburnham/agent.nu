
export def main [
  closure_var_name: string
  --pipe-passthrough
  --args-passthrough
  ...args
] {
  let pipe_data = $in

  let closure = $env
  | get --optional $closure_var_name
  | default {
    { |...args|
      {
        args: ...$args
        in: $in
      }
    }
  }

  let result = $in
  | do $closure ...$args

  match [$pipe_passthrough $args_passthrough] {
    [true false] => {
      $result.in
    }

    [false true] => {
      $result.args
    }

    _ => {
      $result
    }
  }
}
