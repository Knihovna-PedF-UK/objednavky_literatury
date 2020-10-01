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
  ["z302-id"] = "userId",
  ["z37-note-1"] = "note-1",
  ["z37-note-2"] = "note-2",
  ["z302-note-1"] = "note-3",
  ["z302-note-1"] = "note-4",
  ["z302-telephone"] = "tel1",
  ["z302-telephone-2"] = "tel2",
  ["z302-telephone-3"] = "tel3",
  ["z302-telephone-4"] = "tel4",
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
local csv_filename = input .. ".csv"
local tsv = objednavky.make_tsv(messages, {"userId", "mail", "phone", "qrcallno", "name", "submitDate"})
local tsv_file = io.open(csv_filename, "w")
tsv_file:write(tsv)
tsv_file:close()
-- convert tsv file to excel
os.execute('soffice --headless --convert-to xlsx --infilter="CSV:9/44,34,76,1,,1033" ' .. csv_filename)

os.execute("xdg-open ".. input .. ".pdf")

