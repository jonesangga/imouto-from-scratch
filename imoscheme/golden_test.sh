#!/usr/bin/env bash

interpreter="$1"
fail=0

for in_file in tests/golden/*.scm; do
    name=$(basename "$in_file" .scm)
    expect_file="tests/golden/$name.expect"
    out_file="tests/golden/out/$name.out"

    eval "$interpreter \"$in_file\" > \"$out_file\""  # To support literal * in file name.

    if ! cmp -s "$out_file" "$expect_file"; then
        echo "FAIL: $name"
        fail=1
    else
        echo "OK: $name"
    fi
done

exit $fail
