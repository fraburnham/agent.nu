#!/usr/bin/env nu

# Find an run all the tests in a directory tree

let test_files = glob -D $"($env.CURRENT_FILE | path dirname)/**/*.nu"
| where (^grep 'def "test' $it | complete | get exit_code) == 0
| where ($it | path basename) != "run.nu"

for test_file in $test_files {
  nu $test_file
}
