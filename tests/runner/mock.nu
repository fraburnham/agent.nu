# TODO: docs

use std/assert

export const mock_table = "mocks"

export def "assert called with args" [
  mock_identifier: string
  args: any
] {
  let actual = stor open
  | query db $"select count\(1\) from ($mock_table) where id = :id and args = :args" --params {id: $mock_identifier, args: $args}
  | get "count(1)"
  | first

  assert ($actual > 0) $"Mock ($mock_identifier) not called with expected args"
}

export def "assert called times" [
  mock_identifier: string
  times: int
] {
  let actual = stor open
  | query db $"select count\(1\) from ($mock_table) where id = :id" --params {id: $mock_identifier}
  | get "count(1)"
  | first

  # TODO: these need to have enough info to be useful
  assert equal $times $actual $"Mock ($mock_identifier) not called expected number of times"
}

export def "assert called times with args" [
  mock_identifier: string
  args: any
  times: int
] {
  let actual = stor open
  | query db $"select count\(1\) from ($mock_table) where id = :id and args = :args" --params {id: $mock_identifier, args: $args}
  | get "count(1)"
  | first

  assert equal $actual $times $"Mock ($mock_identifier) not called expected number of times with expected args"
}

def "setup db" [] {
  try {
    stor create --table-name $mock_table --columns {id: str, args: jsonb, pipe_data: jsonb}
  } catch { |e|
    if ($e.json | from json | get -o labels.0.text) !~ "already exists in CREATE TABLE" {
      error make $e
    }
  }
}

export def clean [] {
  stor delete --table-name $mock_table
}

export def main [
  mock_identifier: string
  ...args
] {
  let pipe_data = $in

  setup db

  {
    id: $mock_identifier
    pipe_data: $pipe_data
    args: $args
  }
  | stor insert --table-name $mock_table
}
