local M = {}
local default_map = {["ra72bc06000374e3582c79c0c15dfbc90"]="name",rc4d9391b9ba34627ad82aab3000a4550= "callno", r223b7dd8e7fb4f1292eb2a8bdb09fa3c="date", rcda891ad0f374935bccb4e17273bf0b8="barcode", r5f5ef809a901400eb72cda41237c8385="mail" }

function M.parse_csv(text, map)
  -- csv file exported from Thunderbird contains HTML messages.
  -- it is quite messy file. we just want to find all JSON messages
  local map = map or default_map
  local messages = {}
  for message in text:gmatch("(%b{})") do
    local record = {}
    -- cleanup the message a bit
    message = message:gsub('""', '"') -- double "
    message = message:gsub("<.->", "") -- html tags. did we ask for them? off course not!
    -- parse values
    for key, value in message:gmatch('"(.-)"%s*:%s*"(.-)"') do
      -- forms return some form of unique ID instead of field names
      -- try to map them to something usable
      local mapped_key = map[key] or key
      -- replace newlines in call numbers with LaTeX line breaks
      record[mapped_key] = value:gsub('\\n', "\\\\\n")
    end
    messages[#messages+1] = record
  end
  return messages
end

function M.fill_template(template, messages)
  local lines = {}
  local cmd_template = '\\objednavka{$name}{$barcode}{$submitDate}{$date}{$mail}{$callno}%%'
  for i, msg in ipairs(messages) do
    -- simple string interpolation
    lines[i] = cmd_template:gsub("%$([%a]+)", function(key) return msg[key] end)
  end
  local content = table.concat(lines, "\n")
  return template:gsub("{{content}}", content)
end
 

local text = io.read("*all")
local messages = M.parse_csv(text)
local f = io.open("template.tex", "r")
local template = f:read("*a")
f:close()

local content = M.fill_template(template, messages)
print(content)

return M