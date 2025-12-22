local inspect = require("libraries/inspect")
local TT = require("types").TT
local NT = require("types").NT

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
    error(msg)
end


function Parser:parse()
    local stmts = {}
    while not self:eof() do
        table.insert(stmts, self:stmt())
    end
    return stmts
end

function Parser:stmt()
    if self:match(TT.PRINTLN) then
        return self:print_stmt()
    else
        return self:expr_stmt()
    end
end

function Parser:print_stmt()
    local value = self:expr()
    self:consume(TT.SEMICOLON, "expect ';' after value")
    return make(NT.PRINTLN, {value = value})
end

function Parser:expr_stmt()
    local expr = self:expr()
    self:consume(TT.SEMICOLON, "expect ';' after expression")
    return make(NT.EXPR_STMT, {expr = expr})
end

function Parser:expr()
    return self:equality()
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

    while self:match(TT.MINUS, TT.PLUS) do
        local op = self:prevt()
        local right = self:factor()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:factor()
    local left = self:unary()

    while self:match(TT.SLASH, TT.STAR) do
        local op = self:prevt()
        local right = self:unary()
        left = make(NT.BINARY, {left = left, op = op, right = right})
    end

    return left
end

function Parser:unary()
    if self:match(TT.NOT, TT.MINUS) then
        local op = self:prevt()
        local right = self:unary()
        left = make(NT.UNARY, {op = op, right = right})
    end

    return self:primary()
end

function Parser:primary()
    if self:match(TT.FALSE)  then return make(NT.BOOL,   {val = false})        end
    if self:match(TT.TRUE)   then return make(NT.BOOL,   {val = true})         end
    if self:match(TT.NULL)   then return make(NT.NULL,   {val = nil})          end
    if self:match(TT.INT)    then return make(NT.INT,    {val = self:prevv()}) end
    if self:match(TT.STRING) then return make(NT.STRING, {val = self:prevv()}) end

    if self:match(TT.LPAREN) then
        local expr = self:expr()
        self:consume(TT.RPAREN, "expect ')' after expression")
        return make(NT.GROUP, {expr = expr})
    end

    error("expect expression")
end

local function parser(tokens)
    local p = Parser.new(tokens)
    return p:parse()
end

return parser
