local ParserError = require("error").ParserError
local types = require("types")

local TT, NT, primitives = types.TT, types.NT, types.primitives

local function make(tag, props)
    props = props or {}
    props.tag = tag
    return props
end

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
    return setmetatable({ t = tokens, i = 1 }, Parser)
end

function Parser:peekt() return self.t[self.i].type     end
function Parser:peekv() return self.t[self.i].val      end
function Parser:prevt() return self.t[self.i - 1].type end
function Parser:prevv() return self.t[self.i - 1].val  end
function Parser:eof()   return self.i > #self.t        end

function Parser:check(type)
    return not self:eof() and self:peekt() == type
end

function Parser:match(...)
    local types = {...}
    for _, type in ipairs(types) do
        if self:check(type) then
            self:advance()
            return true
        end
    end

    return false
end

function Parser:advance()
    if not self:eof() then
        self.i = self.i + 1
    end
end

function Parser:consume(type, msg)
    if self:check(type) then
        self:advance()
        return
    end
    ParserError(msg)
end


function Parser:parse()
    local stmts = {}
    while not self:eof() do
        table.insert(stmts, self:declaration())
    end
    return stmts
end

function Parser:declaration()
    if self:match(TT.TYPE) then  -- TODO: Should it use match() or check()?
        return self:decl()
    end
    return self:stmt()
end

-- TODO: Refactor. Clean up.
function Parser:decl()
    local type = self:type()

    self:consume(TT.IDENT, "expect identifier")
    local name = self:prevv()

    -- check if next is LParen
    if self:match(TT.LPAREN) then
        -- This is function declaration.
        local params = {}
        if not self:check(TT.RPAREN) then
            repeat
                if #params > 10 then
                    error("too much param")
                end

                self:consume(TT.TYPE, "expect param type")
                local t = self:type()
                self:consume(TT.IDENT, "expect param name")
                local n = self:prevv()

                table.insert(params, {type = t, name = n})
            until not self:match(TT.COMMA)
        end

        self:consume(TT.RPAREN, "expect ')' after arg list")
        self:consume(TT.LBRACE, "expect '{' after function body")
        local body = self:block()
        return make(NT.FUNDECL, {rettype = type, name = name, params = params, body = body})
    else
        -- This is variable declaration.
        local init = nil
        if self:match(TT.EQ) then
            init = self:expr()
        end

        self:consume(TT.SEMICOLON, "expect ';' after var decl")
        return make(NT.VARDECL, {vartype = type, name = name, init = init})
    end
end

-- TODO: Fix this. Rename. Support union. Should consume the type here?
function Parser:type()
    local type = self:prevv()

    -- Only one dimensional array for now.
    if self:match(TT.LSQUARE) then
        self:consume(TT.RSQUARE, "expect ']' after array '['")
        return { kind = "array", name = type }
    end

    return type
end

-- TODO: This is only used by init statement in for loop. Refactor.
function Parser:vardecl()
    local type = self:type()

    self:consume(TT.IDENT, "expect variable name")
    local name = self:prevv()

    local init = nil
    if self:match(TT.EQ) then
        init = self:expr()
    end

    self:consume(TT.SEMICOLON, "expect ';' after var decl")
    return make(NT.VARDECL, {vartype = type, name = name, init = init})
end

function Parser:stmt()
    if self:match(TT.IF) then
        return self:if_stmt()

    elseif self:match(TT.SHOW) then
        return self:show_stmt()

    elseif self:match(TT.RETURN) then
        return self:return_stmt()

    elseif self:match(TT.FOR) then
        return self:for_stmt()

    elseif self:match(TT.WHILE) then
        return self:while_stmt()

    elseif self:match(TT.LBRACE) then
        return make(NT.BLOCK, {stmts = self:block()})

    else
        return self:expr_stmt()
    end
end

function Parser:if_stmt()
    self:consume(TT.LPAREN, "expect '(' after 'if'")
    local cond = self:expr()
    self:consume(TT.RPAREN, "expect ')' after if condition")

    local then_ = self:stmt()
    local else_ = nil
    if self:match(TT.ELSE) then
        else_ = self:stmt()
    end

    return make(NT.IF, {cond = cond, then_ = then_, else_ = else_})
end

function Parser:for_stmt()
    self:consume(TT.LPAREN, "expect '(' after 'for'")

    local init
    if self:match(TT.SEMICOLON) then
        init = nil
    elseif self:match(TT.TYPE) then
        init = self:vardecl()  -- TODO: Think again.
    else
        init = self:expr_stmt()
    end

    local cond = nil
    if not self:check(TT.SEMICOLON) then
        cond = self:expr()
    end
    self:consume(TT.SEMICOLON, "expect ';' after loop condition")

    local incr = nil
    if not self:check(TT.RPAREN) then
        incr = self:expr()
    end
    self:consume(TT.RPAREN, "expect ')' after for clauses")

    local body = self:stmt()

    if incr ~= nil then
        body = make(NT.BLOCK, {stmts = {
            body,
            make(NT.EXPR_STMT, {expr = incr}),
        }})
    end

    if cond == nil then
        cond = make(NT.BOOL, {type = primitives.Bool, val = true})
    end
    body = make(NT.WHILE, {cond = cond, body = body})

    if init ~= nil then
        body = make(NT.BLOCK, {stmts = {init, body}})
    end

    return body
end

function Parser:while_stmt()
    self:consume(TT.LPAREN, "expect '(' after 'while'")
    local cond = self:expr()
    self:consume(TT.RPAREN, "expect ')' after condition")
    local body = self:stmt()
    return make(NT.WHILE, {cond = cond, body = body})
end

function Parser:show_stmt()
    local expr = self:expr()
    self:consume(TT.SEMICOLON, "expect ';' after expr")
    return make(NT.SHOW, {expr = expr})
end

function Parser:return_stmt()
    local expr = nil
    if not self:check(TT.SEMICOLON) then
        expr = self:expr()
    end
    self:consume(TT.SEMICOLON, "expect ';' after return expr")
    return make(NT.RETURN, {expr = expr})
end

function Parser:block()
    local stmts = {}

    while not self:check(TT.RBRACE) and not self:eof() do
        table.insert(stmts, self:declaration())
    end

    self:consume(TT.RBRACE, "expect '}' after block")
    return stmts
end

function Parser:expr_stmt()
    local expr = self:expr()
    self:consume(TT.SEMICOLON, "expect ';' after expression")
    return make(NT.EXPR_STMT, {expr = expr})
end

function Parser:expr()
    return self:assignment()
end

function Parser:assignment()
    local expr = self:or_()

    if self:match(TT.EQ, TT.PLUS_EQ, TT.MINUS_EQ, TT.STAR_EQ, TT.SLASH_EQ) then
        local op = self:prevt()
        local value = self:assignment()

        if expr.tag == NT.VAR then
            local name = expr.name
            return make(NT.ASSIGN, {name = name, value = value, op = op})
        end

        error("invalid assignment target")
    end

    return expr
end

function Parser:or_()
    local left = self:and_()

    while self:match(TT.PIPE2) do
        local op = self:prevt()
        local right = self:and_()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:and_()
    local left = self:equality()

    while self:match(TT.AMP2) do
        local op = self:prevt()
        local right = self:equality()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:equality()
    local left = self:comparison()

    while self:match(TT.EQ_EQ, TT.NOT_EQ) do
        local op = self:prevt()
        local right = self:comparison()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:comparison()
    local left = self:term()

    while self:match(TT.GREATER, TT.GREATER_EQ, TT.LESS, TT.LESS_EQ) do
        local op = self:prevt()
        local right = self:term()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:term()
    local left = self:factor()

    while self:match(TT.MINUS, TT.PLUS, TT.DOT2) do
        local op = self:prevt()
        local right = self:factor()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:factor()
    local left = self:unary()

    while self:match(TT.SLASH, TT.STAR, TT.PERCENT) do
        local op = self:prevt()
        local right = self:unary()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:unary()
    if self:match(TT.NOT, TT.MINUS, TT.HASH) then
        local op = self:prevt()
        local right = self:unary()
        return make(NT.UNARY, {op = op, right = right})
    end

    return self:postfix()
end

function Parser:postfix()
    local expr = self:primary()

    while true do
        if self:match(TT.LPAREN) then
            expr = self:finish_call(expr)
        elseif self:match(TT.LSQUARE) then
            local index_expr = self:expr()
            self:consume(TT.RSQUARE, "expect ']' after indexing")
            expr = make(NT.INDEX, {base = expr, index = index_expr})
        else
            break
        end
    end

    return expr
end

function Parser:finish_call(callee)
    local args = {}
    if not self:check(TT.RPAREN) then
        repeat
            if #args > 10 then
                error("cannot have more that 10 args")
            end
            table.insert(args, self:expr())
        until not self:match(TT.COMMA)
    end

    self:consume(TT.RPAREN, "expect ')' after args")
    return make(NT.CALL, {callee = callee, args = args})
end

function Parser:primary()
    if self:match(TT.FALSE)   then return make(NT.BOOL,   {type = primitives.Bool,   val = false})        end
    if self:match(TT.TRUE)    then return make(NT.BOOL,   {type = primitives.Bool,   val = true})         end
    if self:match(TT.NULL)    then return make(NT.NULL,   {type = primitives.Null})                       end
    if self:match(TT.INT)     then return make(NT.INT,    {type = primitives.Int,    val = self:prevv()}) end
    if self:match(TT.STRING)  then return make(NT.STRING, {type = primitives.String, val = self:prevv()}) end
    if self:match(TT.LRPAREN) then return make(NT.UNIT,   {type = primitives.Unit})                       end

    if self:match(TT.IDENT) then
        return make(NT.VAR, {name = self:prevv()})
    end

    if self:match(TT.LPAREN) then
        local expr = self:expr()
        self:consume(TT.RPAREN, "expect ')' after expression")
        return make(NT.GROUP, {expr = expr})
    end

    if self:match(TT.LSQUARE) then
        local array = {}
        if not self:check(TT.RSQUARE) then
            repeat
                local element = self:expr()
                table.insert(array, element)
            until not self:match(TT.COMMA)
        end

        self:consume(TT.RSQUARE, "expect ']' after array literal")
        return make(NT.ARRAY, {array = array})
    end

    error("expect expression")
end

local function parser(tokens)
    local p = Parser.new(tokens)
    return p:parse()
end

return parser
