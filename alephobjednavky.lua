local dir = arg[0]:gsub("alephobjednavky.lua$","")
package.path = dir .."?.lua;" .. package.path
local objednavky = require "objednavky"

local cmd_template = '\\objednavka{$name}{$barcode}{$submitDate}{$date}{$mail}{$callno}{$id}{$qrcallno}%%'
local map = {
  ["z30-doc-number"] = "barcode",
  ["z302-name"] = "name",
  ["z30-call-no"] = "callno",
  ["z302-key-01"] = "user_barcode",
  ["email-address"] = "mail",
  ["z37-open-date"] = "open_date",
  ["z37-open-hour"] = "open_hour",
  ["bib-info"] = "bibinfo",
  ["z302-id"] = "userId"
}

local input = arg[1]

local messages = objednavky.parse_xml(input, map)
messages = objednavky.make_id(messages, os.date("%m-%d-%H-"))
local f = io.open(dir .. "template.tex", "r")
local template = f:read("*a")
f:close()

local content = objednavky.fill_template(template, messages)
local lualatex = io.popen("lualatex --jobname=" .. input, "w")
lualatex:write(content)
lualatex:close()

--- make csv file for mail merge
local tsv = objednavky.make_tsv(messages, {"mail", "qrcallno", "name", "submitDate"})
local tsv_file = io.open(input .. ".csv", "w")
tsv_file:write(tsv)
tsv_file:close()

os.execute("xdg-open ".. input .. ".pdf")

