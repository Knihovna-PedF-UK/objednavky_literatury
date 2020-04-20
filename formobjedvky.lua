local M = require "objednavky"
local text = io.read("*all")
local messages = M.parse_csv(text)
messages = M.make_id(messages, os.date("%m-%d-"))
local f = io.open("template.tex", "r")
local template = f:read("*a")
f:close()

local content = M.fill_template(template, messages)
print(content)
