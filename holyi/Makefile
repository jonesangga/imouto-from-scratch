test: unit golden golden_error

golden:
	bash golden_test.sh "tests/golden"

golden_error:
	bash golden_test.sh "tests/golden_error"

unit:
	lua tests/unit/lexer_test.lua
	lua tests/unit/parser_test.lua
