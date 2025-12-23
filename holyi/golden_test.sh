#!/usr/bin/env bash

interpreter="lua main.lua"
golden_dir="tests/golden"
fail=0

for in_file in "$golden_dir"/*.hi; do
    # echo "$in_file"
    name=$(basename "$in_file" .hi)
    expect_file="$golden_dir/$name.expect"
    out_file="$golden_dir/out/$name.out"

    eval "$interpreter \"$in_file\" > \"$out_file\"" 2>&1  # To support literal * in file name.

    if ! cmp -s "$out_file" "$expect_file"; then
        echo "FAIL: $name"
        diff -u "$out_file" "$expect_file"
        fail=1
    else
        echo "OK: $name"
    fi
done

exit $fail
