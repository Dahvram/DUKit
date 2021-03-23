-- DUKit Version: 0.7.0

--
-- CONSOLE OUTPUT
--

QUIET=0     -- No console output
ERRORS=1    -- Only errors get output
WARNINGS=2  -- Only errors and warnings get output
DEBUG=3     -- Everything gets output

CONSOLE_LOUDNESS=DEBUG  --export: Console output filter level (QUIET, ERRORS, WARNINGS, DEBUG)

-- Send message to console.
-- msg: text to put to console
-- lvl: the message level (ERRORS, WARNINGS, DEBUG)
function out(msg, lvl)
    local level = lvl or DEBUG
    if level > QUIET and level <= CONSOLE_LOUDNESS then
        system.print(msg)
    end
end

-- Send a debug level message to console.
-- msg: text to put to console
function debug(msg)
    out(msg, DEBUG)
end

-- Send an error level message to console.
-- msg: text to put to console
-- ex: true=raise error and then exit, false=send to console
function err(msg, ex)
    out(msg, ERRORS)
    local ex = ex or true
    if ex then
        error(msg)
        unit.exit()
    end
end

-- Send a warning level message to console.
-- msg: text to put to console
function warn(msg)
    out(msg, WARNINGS)
end

-- Send a debug level message to console and then test condition.
-- condition: condition to test for True
-- errmsg: message output to console on False test condition
-- dbgmsg: debug level text to put to console before test to identify where the test is
function test(condition, errmsg, dbgmsg)
    if not condition then
        if dbgmsg then
            debug(dbgmsg)
        end
        local errmsg = errmsg or "ERROR: Tested conditon was false!"
        err(errmsg, True)
    end
end

--
-- SLOT DETECTION
--

-- Detected Elements
core = nil          -- core unit
container = {}      -- container units
databank = {}       -- databank units
door = {}           -- door units
industry = {}       -- industry units
light = {}          -- light units
screen = {}         -- screen units
sign = {}           -- sign units

-- Auto detect the units that are plugged into the control unit slots.
function autoDetectSlots()
    local slot_name, slot = nil, nil
    for slot_name, slot in pairs(unit) do
        if type(slot) == "table" and type(slot.export) == "table" and slot.getElementClass then
            local element_class = slot.getElementClass():lower()
            local id = slot.getId()
            local json_data = slot.getData()
            if element_class == "coreunitstatic" then
                if core then
                    error("ERROR: Only one static core supported at this time!")
                end
                core = slot
                debug("Found static core")
            elseif element_class == "databankunit" then
                table.insert(databank, slot)
                debug("Found databank #"..#databank)
            elseif element_class == "doorunit" then
                table.insert(door, slot)
                debug("Found door #"..#door)
            elseif element_class == "industry1" or element_class == "industry2" or element_class == "industry3" or element_class == "industry4" then
                table.insert(industry, slot)
                debug("Found industry #"..#industry)
            elseif element_class == "itemcontainer" then
                table.insert(container, slot)
                debug("Found container #"..#container)
            elseif element_class == "lightunit" then
                table.insert(light, slot)
                debug("Found light #"..#light)
            elseif element_class == "screenunit" then
                table.insert(screen, slot)
                debug("Found screen #"..#screen)
            elseif element_class == "screensignunit" then
                table.insert(sign, slot)
                debug("Found sign #"..#sign)
            else
                debug("slot class '"..element_class.."' of type '"..type(slot).."' in "..slot_name, INFO)
                debug("  slot ID = "..id)
                debug("  slot data = "..json_data)
            end
        end
    end
end

--
-- UTILITIES
--

-- Get the name of the player that activated this unit.
-- returns the player name as a string
function getPlayerName()
    local player_id = unit.getMasterPlayerId()
    local player_name = system.getPlayerName(player_id)
    return player_name
end

-- Convert the specified value to an integer.
-- n: the value to try and convert
-- returns the integer value
-- An error will be raised if the value cannot be converted.
function toInt(n)
    local t = n
    if t and type(t) == "string" then
        t = tonumber(t)
    end
    if t and type(t) == "number" then
        local i = math.floor(t)
        if i < t then
            i = i + 1
        end
        return i
    end
    err("ERROR: Unable to convert value '"..n.."' to integer!")
end

-- Convert the specified value to a number.
-- n: the value to try and convert
-- returns the integer value
-- An error will be raised if the value cannot be converted.
function toNum(n)
    local t = n
    if t and type(t) == "string" then
        t = tonumber(t)
    end
    if t and type(t) == "number" then
        return t
    end
    err("ERROR: Unable to convert value '"..n.."' to number!")
end

-- Convert the specified value to a string.
-- n: the value to convert
-- returns the string value
-- An error will be raised if the value cannot be converted.
function toStr(n)
    local t = n
    if t and type(t) == "number" then
        t = tostring(t)
    end
    if t and type(t) == "string" then
        return t
    end
    err("ERROR: Unable to convert value '"..n.."' to string!")
end

-- Select and use an element.
-- unit_table: the table of elements to select from
-- table_index: index of the unit in the table to use (0 will iterate all units in table)
-- unit_op: the function to call with the selected unit
-- data: data to be passed to the unit_op function
function use(unit_table, table_index, unit_op, data)
    test(unit_table, "A unit table must be provided!")
    test(table_index and (type(table_index) == "number"), "A unit index must be provided!")
    test((table_index >= 0) and (table_index <= #unit_table), "The unit index must be a value from 0 to "..#unit_table.."!")
    test(unit_op, "A unit operation function must be provided!")
    local data = data or nil
    if table_index == 0 then
        for i, u in pairs(unit_table) do
            unit_op(i, u, data)
        end
    else
        unit_op(table_index, unit_table[table_index], data)
    end
end

--
-- COLOR UTILITIES
--
-- Utility functions and values to support color calculations.
--

RGB_BLACK   = {  0,  0,  0}
RGB_WHITE   = {255,255,255}
RGB_RED     = {255,  0,  0}
RGB_YELLOW  = {255,255,  0}
RGB_GREEN   = {  0,255,  0}
RGB_CYAN    = {  0,255,255}
RGB_BLUE    = {  0,  0,255}
RGB_MAGENTA = {255,  0,255}

-- Normalize a radian value to be in the range -pi to pi.
-- r: the radian value to normalize
-- returns the normalized radians value
function normalizeRadians(r)
    while r < -math.pi do
        r = r + (2 * math.pi)
    end
    while r > math.pi do
        r = r - (2 * math.pi)
    end
    return r
end

-- Normalize an RGB list.
-- rgb: a list of values (i.e. { r, g, b })
-- returns the normalized RGB list
function normalizeRGB(rgb)
    local r = math.max(math.min(math.floor(rgb[1]), 255), 0)
    local g = math.max(math.min(math.floor(rgb[2]), 255), 0)
    local b = math.max(math.min(math.floor(rgb[3]), 255), 0)
    return {r, g, b}
end

-- Calculate the azimuth between the two colors (0=red, 90=blue).
-- This function implements support for the RGB Color Space ("Color Cube")
-- s_rgb: source RGB value
-- t_rgb: target RGB value
-- to_radians: [optional] true=result in radians (default: false=result in degrees)
-- returns the value for the azimuth between the two colors
function calcColorAzimuth(s_rgb, t_rgb, to_radians)
    function atan_br(rgb)
        local r = rgb[1] / 255
        local b = rgb[3] / 255
        if r == 0 then
            if b == 0 then
                return 0
            end
            return math.asin(b)
        end
        return math.atan(b/r)
    end
    local s_rgb = normalizeRGB(s_rgb)
    local t_rgb = normalizeRGB(t_rgb)
    local to_radians = to_radians or false
    local s = atan_br(s_rgb)
    local t = atan_br(t_rgb)
    s = normalizeRadians(s)
    t = normalizeRadians(t)
    local a = t - s
    if not to_radians then
        a = math.floor(math.deg(a))
    end
    return a
end

-- Calculate the elevation between the two colors (0=no green, 90=green).
-- This function implements support for the RGB Color Space ("Color Cube")
-- s_rgb: source RGB value
-- t_rgb: target RGB value
-- to_radians: [optional] true=result in radians (default: false=result in degrees)
-- returns the value for the elevation between the two colors
function calcColorElevation(s_rgb, t_rgb, to_radians)
    local s_rgb = normalizeRGB(s_rgb)
    local t_rgb = normalizeRGB(t_rgb)
    local to_radians = to_radians or false
    local s = math.asin(s_rgb[2] / 255)
    local t = math.asin(t_rgb[2] / 255)
    local e = t - s
    e = normalizeRadians(e)
    if not to_radians then
        e = math.floor(math.deg(e))
    end
    return e
end

-- Calculate the distance between the two colors.
-- This function implements support for the RGB Color Space ("Color Cube")
-- The distance is typically calculated from the origin color (i.e. RGB_BLACK)
-- s_rgb: source RGB value
-- t_rgb: target RGB value
-- returns the value for the distance between the two colors
function calcColorDistance(s_rgb, t_rgb)
    local s_rgb = normalizeRGB(s_rgb)
    local t_rgb = normalizeRGB(t_rgb)
    local dr = t_rgb[1] - s_rgb[1]
    local dg = t_rgb[2] - s_rgb[2]
    local db = t_rgb[3] - s_rgb[3]
    local d = math.sqrt((dr * dr) + (dg * dg) + (db * db))
    return d
end

-- Calculate an RGB value from the azimuth, elevation, and distance components.
-- This function implements support for the RGB Color Space ("Color Cube")
-- azim: the azimuth value (0=red, 90=blue)
-- elev: the elevation value (0=no green, 90=full green)
-- dist: the distance value (0=black, 442=full intensity)
-- is_radians: true=azim and eliv are in radians (default false=degrees)
-- returns the calculated RGB list
function calcRGBFromAED(azim, elev, dist, is_radians)
    test((azim>=0) and (azim<=90), "Azimuth must be between 0 and 90!")
    test((elev>=0) and (elev<=90), "Elevation must be between 0 and 90!")
    local is_radians = is_radians or false
    local a = azim
    local e = elev
    if not is_radians then
        a = math.rad(a)
        e = math.rad(e)
    end
    local r = dist * math.cos(a) * math.cos(e)
    local b = dist * math.sin(a) * math.cos(e)
    local g = dist * math.sin(e)
    if not r then
        r = 0
    end
    if not g then
        g = 0
    end
    if not b then
        b = 0
    end
    local rgb = normalizeRGB({r, g, b})
    return rgb
end

--
-- TABLE UTILITIES
--
-- Utility functions to support a table of strings, numbers or objects.
--

local TABLE_ERROR = "ERROR: A table must be provided!"
local INDEX_ERROR = "ERROR: An index must be provided!"
local KEY_ERROR   = "ERROR: A key must be provided!"
local JSON_ERROR  = "ERROR: A JSON string must be provided!"

-- Create an empty table.
-- returns an empty table
function tableCreate()
    return {}
end

-- Get the number of items in the specified table.
-- tbl: the table to get item count for
-- returns the number of items in table
function tableCount(tbl)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableCount(tbl)")
    local len = 0
    for k, v in pairs(tbl) do
        len = len + 1
    end
    return len
end

-- Append an item to the end of a table (list mode).
-- tbl: the table to modify
-- itm: the item to append
function tableAppendItem(tbl, itm)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableAppendItem(tbl, itm)")
    table.insert(tbl, itm)
end

-- Add/Replace an item in a table (map mode).
-- tbl: the table to modify
-- key: the key for the entry
-- itm: the value for the entry
function tableAddItem(tbl, key, itm)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableAddItem(tbl, itm, key)")
    test(key and (type(key) == "number" or type(key) == "string"), KEY_ERROR, "TEST: Invalid key in tableAddItem(tbl, itm, key)")
    tbl[key] = itm
end

-- Insert an item in a table (list mode).
-- tbl: the table to modify
-- idx: the index for the entry
-- itm: the value for the entry
function tableInsertItem(tbl, idx, itm)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableInsertItem(tbl, itm, idx)")
    test(idx and (type(idx) == "number"), INDEX_ERROR, "TEST: Invalid index in tableInsertItem(tbl, itm, idx)")
    table.insert(tbl, itm, idx)
end

-- Find the first item in a table that matches the specified value and return its key.
-- tbl: the table to search
-- itm: the falue of the entry to look for
-- returns the index of the first occurrence of itm (nil=not found)
function tableFindItemKey(tbl, itm)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableFindItemKey(tbl, itm)")
    for k, t in pairs(tbl) do
        if t == itm then
            return k
        end
    end
    return nil
end

-- Remove the first occurrence of an item from a table.
-- tbl: the table to search
-- itm: the value of the entry to remove
function tableRemoveItem(tbl, itm)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableRemoveItem(tbl, itm)")
    local key = tableFindItemKey(tbl, itm)
    if key then
        tableRemoveItemAt(tbl, key)
    end
end

-- Remove the item with the specified key/index from a table.
-- tbl: the table to modify
-- key: the key/index of the entry to remove
function tableRemoveItemAt(tbl, key)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableRemoveItemAt(tbl, key)")
    test(key and (type(key) == "number" or type(key) == "string"), KEY_ERROR, "TEST: Invalid key in tableRemoveItemAt(tbl, key)")
    table.remove(tbl, key)
end

-- Get the item with the specified key/index from a table.
-- tbl: the table to use
-- key: the key/index of the entry
-- default: the value to return if the key/index is not found (default is nil)
-- returns the entry at the key/index or the specified default value
function tableItemAt(tbl, key, default)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableItemAt(tbl, key)")
    test(key and (type(key) == "number" or type(key) == "string"), KEY_ERROR, "TEST: Invalid key in tableItemAt(tbl, key)")
    local t = tbl[key]
    if t == nil then
        t = default
    end
    return t
end

-- Show the contents of a table.
-- This uses the debug output function.
-- tbl: the table to display
-- indent_str: the indent sting to use for indenting on the console
-- NOTE: system.print() appears to strip spaces from the start and end of string being printed.
function tableShow(tbl, indent_str)
    indent_str = indent_str or "__"
    local level = 0
    local tables = {}
    function printLine(s)
        local t = ""
        for i = 0, level, 1 do
            t = t..indent_str
        end
        t = t..s
        debug(t)
    end
    function walkTable(tbl, s)
        local i = tableFindItemKey(tables, tbl)
        local s = s or ""
        local n = i or tableCount(tables) + 1
        s = s.."<table-"..n..">["..tableCount(tbl).."]".."{"
        printLine(s)
        level = level + 1
        if not i then
            tableAppendItem(tables, tbl)
            local quote_key = (tableType(tbl) == "map")
            for k, v in pairs(tbl) do
                s = ""
                if quote_key then
                    s = s.."\""..k.."\":"
                else
                    s = s..k..":"
                end
                if v then
                    t = type(v)
                    u = s.."<"..t..">"
                    if t == "table" then
                        walkTable(v, s)
                    elseif t == "number" then
                        printLine(u..v)
                    elseif t == "boolean" then
                        if v then
                            printLine(u.."true")
                        else
                            printLine(u.."false")
                        end
                    elseif t == "function" then
                        printLine(u.."()")
                    else
                        printLine(u.."\""..v.."\"")
                    end
                else
                    printLine(s.."\"nil\"")
                end
            end
        end
        level = level - 1
        printLine("}")
    end
    walkTable(tbl)
end

-- Get the type of a table (i.e. "list" or "map").
-- tbl: the table to identify.
-- returns the table type
function tableType(tbl)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableType(tbl)")
    for k, _ in pairs(tbl) do
        if not (type(k) == "number") then
            return "map"
        end
    end
    return "list"
end

-- Convert a table to a JSON string.
-- tbl: the table to convert
-- returns a JSON string representation of the table
function tableToJsonString(tbl)
    test(tbl and type(tbl) == "table", TABLE_ERROR, "TEST: Invalid table in tableToJsonString(tbl)")
    local jsn = json.encode(tbl)
    return jsn
end

-- Convert a JSON string to a table.
-- jsn: the JSON string to convert
-- returns a table containing the values from the JSON string
function jsonStringToTable(jsn)
    test(jsn and type(jsn) == "string", JSON_ERROR, "TEST: Invalid JSON string in jsonStringToTable(jsn)")
    local tbl = json.decode(jsn)
    return tbl
end

--
-- DOOR UNIT
--

-- Close a door.
-- i: door index (0=all)
function doorClose(i)
    function op(i, unit, data)
        unit.deactivate()
        debug("Closed door #"..i)
    end
    use(door, i, op)
end

-- Open a door.
-- i: door index (0=all)
function doorOpen(i)
    function op(i, unit, data)
        unit.activate()
        debug("Opened door #"..i)
    end
    use(door, i, op)
end

-- Get the state of a door.
-- i: door index
-- return the door state (1=open, 0=closed)
function doorGetState(i)
    test(i and (type(i) == "number"), "A unit index must be provided!")
    test((i > 0) and (i <= #door), "The unit index must be a value from 1 to "..#door.."!")
    debug("Getting state for door #"..i)
    st = door[i].getState()
    return st
end

-- Toggle the state of a door.
-- i: door index (0=all)
function doorToggle(i)
    function op(i, unit, data)
        unit.toggle()
        debug("Toggled state for door #"..i)
    end
    use(door, i, op)
end

--
-- LIGHT UNIT
--

-- Activate a light.
-- i: light index (0=all)
function lightActivate(i)
    function op(i, unit, data)
        unit.activate()
        debug("Activated light #"..i)
    end
    use(light, i, op)
end

-- Deactivate a light.
-- i: light index (0=all)
function lightDeactivate(i)
    function op(i, unit, data)
        unit.deactivate()
        debug("Deactivated light #"..i)
    end
    use(light, i, op)
end

-- Get the perceived brightness of a light.
-- i: light index
-- returns the brightness of the light
function lightGetBrightness(i)
    test(i and (type(i) == "number"), "A unit index must be provided!")
    test((i > 0) and (i <= #light), "The unit index must be a value from 1 to "..#light.."!")
    debug("Getting brightness for light #"..i)
    rgb = lightGetRGBColor(i)
    local br = math.sqrt((0.299 * rgb[1] * rgb[1]) + (0.587 * rgb[2] * rgb[2]) + (0.114 * rgb[3] * rgb[3]))
    return br
end

-- Get the RGB color of a light.
-- i: light index
-- returns the RGB color of the light
function lightGetRGBColor(i)
    test(i and (type(i) == "number"), "A unit index must be provided!")
    test((i > 0) and (i <= #light), "The unit index must be a value from 1 to "..#light.."!")
    debug("Getting RGB for light #"..i)
    rgb = light[i].getRGBColor()
    debug(rgb[1]..","..rgb[2]..","..rgb[3])
    return rgb
end

-- Get the state of a light.
-- i: light index
-- returns the state of the light (1=on, 0=off)
function lightGetState(i)
    test(i and (type(i) == "number"), "A unit index must be provided!")
    test((i > 0) and (i <= #light), "The unit index must be a value from 1 to "..#light.."!")
    debug("Getting state for light #"..i)
    st = light[i].getState()
    return st
end

-- Set the RGB color of a light.
-- i: light index (0=all)
-- rgb: the RGB color to set
function lightSetRGBColor(i, rgb)
    function op(i, unit, rgb)
        unit.setRGBColor(rgb[1],rgb[2],rgb[3])
        debug("Set RGB for light #"..i)
    end
    use(light, i, op, rgb)
end

-- Toggle the state of a light.
-- i: light index (0=all)
function lightToggle(i)
    function op(i, unit, data)
        unit.toggle()
        debug("Toggled state for light #"..i)
    end
    use(light, i, op)
end

--
-- SCREEN UNIT
--

-- Activate a screen.
-- i: screen index (0=all)
function screenActivate(i)
    function op(i, unit, data)
        unit.activate()
        debug("Activated screen #"..i)
    end
    use(screen, i, op)
end

-- Deactivate a screen.
-- i: screen index (0=all)
function screenDeactivate(i)
    function op(i, unit, data)
        unit.deactivate()
        debug("Deactivated screen #"..i)
    end
    use(screen, i, op)
end

-- Clear a screen.
-- i: screen index (0=all)
function screenClear(i)
    function op(i, unit, data)
        unit.clear()
        debug("Cleared screen #"..i)
    end
    use(screen, i, op)
end

-- Set a screen with HTML.
-- i: screen index (0=all)
-- html: the HTML to set
function screenSetHTML(i, html)
    function op(i, unit, html)
        unit.setHTML(html)
        debug("Set HTML on screen #"..i)
    end
    use(screen, i, op, html)
end

-- Set a screen with SVG.
-- i: screen index (0=all)
-- svg: the SVG to set
function screenSetSVG(i, svg)
    function op(i, unit, svg)
        unit.setSVG(svg)
        debug("Set SVG on screen #"..i)
    end
    use(screen, i, op, svg)
end

-- Set a screen with text.
-- i: screen index (0=all)
-- text: the text to set
function screenSetText(i, text)
    function op(i, unit, text)
        unit.setCenteredText(text)
        debug("Set text on screen #"..i)
    end
    use(screen, i, op, text)
end

--
-- SIGN UNIT
--

-- Activate a sign.
-- i: sign index (0=all)
function signActivate(i)
    function op(i, unit, data)
        unit.activate()
        debug("Activated sign #"..i)
    end
    use(sign, i, op)
end

-- Deactivate a sign.
-- i: sign index (0=all)
function signDeactivate(i)
    function op(i, unit, data)
        unit.deactivate()
        debug("Deactivated sign #"..i)
    end
    use(sign, i, op)
end

-- Clear a sign.
-- i: sign index (0=all)
function signClear(i)
    function op(i, unit, data)
        unit.clear()
        debug("Cleared sign #"..i)
    end
    use(sign, i, op)
end

-- Set a sign with HTML.
-- i: sign index (0=all)
-- html: the HTML to set
function signSetHTML(i, html)
    function op(i, unit, html)
        unit.setHTML(html)
        debug("Set HTML on sign #"..i)
    end
    use(sign, i, op, html)
end

-- Set a sign with SVG.
-- i: sign index (0=all)
-- svg: the SVG to set
function signSetSVG(i, svg)
    function op(i, unit, svg)
        unit.setSVG(svg)
        debug("Set SVG on sign #"..i)
    end
    use(sign, i, op, svg)
end

-- Set a sign with text.
-- i: sign index (0=all)
-- text: the text to set
function signSetText(i, text)
    function op(i, unit, text)
        unit.setCenteredText(text)
        debug("Set text on sign #"..i)
    end
    use(sign, i, op, text)
end
