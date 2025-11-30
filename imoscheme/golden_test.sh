#!/usr/bin/env bash

fail=0

for in_file in tests/golden/*.scm; do
    name=$(basename "$in_file" .scm)
    expect_file="tests/golden/$name.expect"
    out_file="tests/golden/out/$name.out"

    lua main.lua "$in_file" > "$out_file"

    if ! cmp -s "$out_file" "$expect_file"; then
        echo "FAIL: $name"
        fail=1
    else
        echo "OK: $name"
    fi
done

exit $fail
