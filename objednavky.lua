local M = {}
require "utf8"
local default_map = {["ra72bc06000374e3582c79c0c15dfbc90"]="name",rc4d9391b9ba34627ad82aab3000a4550= "callno", r223b7dd8e7fb4f1292eb2a8bdb09fa3c="date", rcda891ad0f374935bccb4e17273bf0b8="barcode", r5f5ef809a901400eb72cda41237c8385="mail" }
local parse_prir = require "parse_prir"


local get_call_no = function(a)
  local letter, digit = a:match("([0-9]*[a-zA-Z]+)([0-9]+)") 
  letter = letter or ""
  digit = digit or "0"
  return letter, tonumber(digit)
end

local function sort_callnos_table(t)
  table.sort(t, function(a,b)
    -- callno looks like F2322
    -- we need to get the letter part and number part separatelly
    local s1, n1 = get_call_no(a) 
    local s2, n2 = get_call_no(b)
    if s1 == s2 then 
      return n1 < n2
    end
    return s1 < s2
  end)
end

local function sort_callnos(callnos)
  -- sort call numbers 
  local t  = {}
  -- explode lines
  for line in callnos:gmatch("([^\n]+)") do
    t[#t+1] = line
  end
  sort_callnos_table(t)
  return table.concat(t, "\n")
end

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
    record["callno"] =  sort_callnos(record["callno"])
    messages[#messages+1] = record
  end

  return messages
end

local function remap_records(records, map)
  local records = records or {}
  local new = {}
  for i = 1, #records do
    rec = records[i]
    local newrec = {date=""} -- we don't use date in this case
    for k,v in pairs(rec) do
      if map[k] then
        newrec[map[k]] = v
      end
    end
    new[#new+1] = newrec
  end
  return new
end

local function sort_aleph_callnos(items)
  -- items from Aleph contain callno and title. sort them by callno
  local callnos = {}
  local backmap = {}
  local sorted = {}
  for _, item in ipairs(items) do
    callnos[#callnos + 1] = item.callno
    backmap[item.callno] = item.title
  end
  sort_callnos_table(callnos)
  for _, callno in ipairs(callnos) do
    sorted[#sorted+1] = {callno= callno, title = backmap[callno]}
  end
  return sorted
end

local function get_joined_callnos(items) 
  local t = {}
  for _, item in ipairs(items) do t[#t+1] = item.callno end
  return table.concat(t, ", ")
end

local function get_callnos_for_print(items)
  -- get callnos and titles 
  local t = {}
  for _, item in ipairs(items) do 
    -- insert only first 10 characters of title,in order to prevent overflow
    local codepoints = {utf8.codepoint(item.title, 1, 25)}
    local title = {}
    for _, c in ipairs(codepoints) do title[#title+1]  = utf8.char(c) end
    t[#t+1] = string.format('\\textbf{%s} -- %s', item.callno, table.concat(title)) 
  end
  return table.concat(t, "\\\\\n")
end

-- join records for each person
local function join_records(records)
  local persons = {}
  for i = 1, #records do
    local rec = records[i]
    local id = rec["user_barcode"]
    local person = persons[id] 
    if not person then
      person = {items = {}} -- 
      for k,v in pairs(rec) do person[k] = v end
      person.callno = "" -- we need to collect call numbers
      person.pos = i -- we want to sort persons as they appeared in the xml file
      person.barcode = id --overwrite barcode
      person.submitDate = rec.open_date .. " " .. rec.open_hour -- construct submit time
      persons[id] = person 
    end
    local title = rec.bibinfo:match("^([^%/]+)") or ""
    table.insert(person.items , {callno =rec.callno, title = title})
    -- person.callno = person.callno ..  rec.callno .."\\\\\n" -- join callnumbers with newlines
  end
  -- make new sorted table
  local newrecords = {}
  for _, record in pairs(persons) do
    local sorted_items = sort_aleph_callnos(record.items)
    record.callno = get_callnos_for_print(sorted_items)
    record.qrcallno = get_joined_callnos(sorted_items) -- simplified callnos for QR code
    -- record["callno"] =  sort_callnos(record["callno"]) -- sort call numbers
    newrecords[#newrecords + 1] = record
  end
  table.sort(newrecords, function(a,b) return a.pos < b.pos end)
  return newrecords

end

-- delete spurious lines from the input
local function clean_xml(input_file)
  local newinput = os.tmpname()
  local f = io.open(newinput, "w")
  -- copy lines, but ignore what we don't want to be in the new xml file
  for line in io.lines(input_file) do
    local z302key = line:match("z302%-key%-([0-9]+)")
    -- ignore z302 keys that are not z302-key-01
    if z302key == "01" or z302key == nil then
      f:write(line .."\n")
    end
  end
  f:close()
  return newinput
  
end


function M.parse_xml(inputfile, map)
  -- map should be in the format {xmltag="name"}
  -- find xml tags position in the xml file
  local xml_tags={}
  for k, _ in pairs(map) do xml_tags[#xml_tags+1] = k end
  -- clean xml and make temp file
  local newinput = clean_xml(inputfile)
  local f = parse_prir.load_file(newinput)
  local root =  "section-01"
  local pos = parse_prir.find_pos(f, xml_tags, root)
  parse_prir.make_saves(pos)
  local records = parse_prir.parse(f, root)
  -- remove temp file
  os.remove(newinput)
  local newrecords = remap_records(records, map)
  return join_records(newrecords)
end

-- add unique ID to each receipt
function M.make_id(messages, prefix)
  for i, msg in ipairs(messages) do
    msg["id"] = prefix .. i
  end
  return messages
end

function M.fill_template(template, messages)
  local lines = {}
  local cmd_template = '\\objednavka{$name}{$barcode}{$submitDate}{$date}{$mail}{$callno}{$id}{$userId}{$qrcallno}%%'
  for i, msg in ipairs(messages) do
    -- simple string interpolation
    lines[i] = cmd_template:gsub("%$([%a]+)", function(key) return msg[key] end)
  end
  local content = table.concat(lines, "\n")
  return template:gsub("{{content}}", content)
end
 

function M.make_tsv(messages, used_fields)
  local t = {}
  local header = {}
  local used_fields = used_fields or {}
  local to_print = {}
  for _, x in ipairs(used_fields) do
    to_print[x] = true 
  end
  local row_to_tsv = function(row)
    local t = {}
    for i, val in ipairs(row) do 
      if type(val) ~= "table"  then
        t[#t+1] = '"' .. val .. '"' 
      end
    end
    return table.concat(t, "\t")
  end
  local make_row = function(row, header)
    local t = {}
    for _, column in ipairs(header) do t[#t+1] =  row[column] end
    return t
  end
  --make header first
  for k, _ in pairs(messages[1]) do if to_print[k] then header[#header+1] =  k end end
  table.sort(header) -- I just don't want the random order
  t[#t+1] = row_to_tsv(header)
  for _, row in ipairs(messages) do
    t[#t+1]  = row_to_tsv(make_row(row,header))
  end
  return table.concat(t, "\n")

end

return M
