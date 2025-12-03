repl:
	rlwrap lua main.lua

test: unit_test golden_test_imo golden_test_chicken golden_test_guile

unit_test:
	lua tests/unit/tokenize_test.lua
	lua tests/unit/parse_test.lua
	lua tests/unit/types_test.lua

golden_test_imo:
	bash golden_test.sh "lua main.lua"

golden_test_chicken:
	bash golden_test.sh "chicken-csi -s"

golden_test_chibi:
	bash golden_test.sh "chibi-scheme -xchibi"

golden_test_guile:
	bash golden_test.sh "guile --no-auto-compile"
