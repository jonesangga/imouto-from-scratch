#!/usr/bin/env bash

interpreter="$1"
golden_dir="$2"
fail=0

for in_file in "$golden_dir"/*.scm; do
    # echo "$in_file"
    name=$(basename "$in_file" .scm)
    expect_file="$golden_dir/$name.expect"
    out_file="$golden_dir/out/$name.out"

    eval "$interpreter \"$in_file\" > \"$out_file\""  # To support literal * in file name.

    if ! cmp -s "$out_file" "$expect_file"; then
        echo "FAIL: $name"
        fail=1
    else
        echo "OK: $name"
    fi
done

exit $fail
