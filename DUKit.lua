-- DUKit Version: 0.11.0

--
-- CONSOLE OUTPUT
--

QUIET=0     -- No console output
ERRORS=1    -- Only errors get output
WARNINGS=2  -- Only errors and warnings get output
DEBUG=3     -- Everything gets output

CONSOLE_LOUDNESS=ERRORS  --export: Console output filter level (QUIET, ERRORS, WARNINGS, DEBUG)

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
-- UTILITIES
--

-- Get the name of the player that activated this unit.
-- returns the player name as a string
function getPlayerName()
    local player_id = unit.getMasterPlayerId()
    local player_name = system.getPlayerName(player_id)
    return player_name
end

-- Round a number to the specified decimal place.
-- n: number to round
-- places: the decimal places to round to
-- returns the rounded number
function round(n, places)
    local mult = 10 ^ (places or 0)
    if places ~= nil then
        return math.floor(n * mult + 0.5) / mult
    else
        return math.floor((n * mult + 0.5) / mult)
    end
end

-- Convert the specified value to a number.
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
    if t == nil then
        return "nil"
    end
    err("ERROR: Unable to convert value '"..n.."' to string!")
end

-- Select and use an element.
-- unit_table: the table of elements to select from
-- unit_id: id of the unit in the table to use (nil/"nil" will iterate all units in table)
-- unit_op: the function to call with the selected unit
-- data: data to be passed to the unit_op function
function use(unit_table, unit_id, unit_op, data)
    if unit_id == nil or unit_id == "nil" then
        for id, u in pairs(unit_table) do
            unit_op(id, u, data)
        end
        return
    end
    unit_id = toStr(unit_id)
    unit_op(unit_id, unit_table[unit_id], data)
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

-- Get the number of items in the specified table.
-- tbl: the table to get item count for
-- returns the number of items in table
function tableCount(tbl)
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
    table.insert(tbl, itm)
end

-- Add/Replace an item in a table (map mode).
-- tbl: the table to modify
-- key: the key for the entry
-- itm: the value for the entry
function tableAddItem(tbl, key, itm)
    tbl[key] = itm
end

-- Insert an item in a table (list mode).
-- tbl: the table to modify
-- idx: the index for the entry
-- itm: the value for the entry
function tableInsertItem(tbl, idx, itm)
    table.insert(tbl, itm, idx)
end

-- Find the first item in a table that matches the specified value and return its key.
-- tbl: the table to search
-- itm: the falue of the entry to look for
-- returns the index of the first occurrence of itm (nil=not found)
function tableFindItemKey(tbl, itm)
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
    local key = tableFindItemKey(tbl, itm)
    if key then
        tableRemoveItemAt(tbl, key)
    end
end

-- Remove the item with the specified key/index from a table.
-- tbl: the table to modify
-- key: the key/index of the entry to remove
function tableRemoveItemAt(tbl, key)
    table.remove(tbl, key)
end

-- Get the item with the specified key/index from a table.
-- tbl: the table to use
-- key: the key/index of the entry
-- default: the value to return if the key/index is not found (default is nil)
-- returns the entry at the key/index or the specified default value
function tableItemAt(tbl, key, default)
    local t = tbl[key]
    if t == nil then
        t = default
    end
    return t
end

-- Iterate a table and process each key, value pair with the provided function.
-- tbl: the table to iterate
-- func: the function to call with the key and value
function tableIterate(tbl, func)
    if tbl and func then
        for k, v in pairs(tbl) do
            func(k, v)
        end
    end
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
    local jsn = json.encode(tbl)
    return jsn
end

-- Convert a JSON string to a table.
-- jsn: the JSON string to convert
-- returns a table containing the values from the JSON string
function jsonStringToTable(jsn)
    local tbl = json.decode(jsn)
    return tbl
end

--
-- SLOT DETECTION
--

-- Auto detect the units that are plugged into the control unit slots.
function autoDetectSlots()
    local auto_slots = unit["auto_detect_slots"]
    if not auto_slots then
        auto_slots = {}
        unit["auto_detect_slots"] = auto_slots
        auto_slots["core"] = {}
        auto_slots["container"] = {}
        auto_slots["databank"] = {}
        auto_slots["door"] = {}
        auto_slots["industry"] = {}
        auto_slots["light"] = {}
        auto_slots["screen"] = {}
        auto_slots["sign"] = {}
        local slot_name, slot = nil, nil
        for slot_name, slot in pairs(unit) do
            if type(slot) == "table" and type(slot.export) == "table" and slot.getElementClass then
                local element_class = slot.getElementClass():lower()
                local id = toStr(slot.getId())
                local json_data = slot.getData()
                if element_class == "coreunitstatic" then
                    if tableCount(auto_slots["core"]) == 1 then
                        error("ERROR: Only one static core supported at this time!")
                    end
                    tableAddItem(auto_slots["core"], id, slot)
                    debug("Found static core (id:"..id..")")
                elseif element_class == "databankunit" then
                    tableAddItem(auto_slots["databank"], id, slot)
                    debug("Found databank (id:"..id..")")
                elseif element_class == "doorunit" then
                    tableAddItem(auto_slots["door"], id, slot)
                    debug("Found door (id:"..id..")")
                elseif element_class == "industry1" or element_class == "industry2" or element_class == "industry3" or element_class == "industry4" then
                    tableAddItem(auto_slots["industry"], id, slot)
                    debug("Found industry (id:"..id..")")
                elseif element_class == "itemcontainer" then
                    tableAddItem(auto_slots["container"], id, slot)
                    debug("Found container (id:"..id..")")
                elseif element_class == "lightunit" then
                    tableAddItem(auto_slots["light"], id, slot)
                    debug("Found light (id:"..id..")")
                elseif element_class == "screenunit" then
                    tableAddItem(auto_slots["screen"], id, slot)
                    debug("Found screen (id:"..id..")")
                elseif element_class == "screensignunit" then
                    tableAddItem(auto_slots["sign"], id, slot)
                    debug("Found sign (id:"..id..")")
                else
                    debug("slot class '"..element_class.."' of type '"..type(slot).."' in "..slot_name, INFO)
                    debug("  slot ID = "..id)
                    debug("  slot data = "..json_data)
                end
            end
        end
    end
end

--
-- CONTAINER UNIT
--

-- Get the number of containers.
function containerCount()
    debug("Getting the count of containers")
    return tableCount(unit["auto_detect_slots"]["container"])
end

-- Get the mass of the items in the container (in kg).
-- id: the ID of the container
-- Returns the mass of the contents
function containerGetItemsMass(id)
    id = toStr(id)
    debug("Getting mass of items in container ["..id.."]")
    local m = unit["auto_detect_slots"]["container"][id].getItemsMass()
    debug(m)
    return m
end

-- Get the volume of the items in the container (in L).
-- id: the id of the container
-- Returns the volume of the contents
function containerGetItemsVolume(id)
    id = toStr(id)
    debug("Getting volume of items in container ["..id.."]")
    local v = unit["auto_detect_slots"]["container"][id].getItemsVolume()
    debug(v)
    return v
end

-- Get the maximum volume the container can hold (in L).
-- id: the id of the container
-- Return the container maximum volume
function containerGetMaxVolume(id)
    id = toStr(id)
    debug("Getting maximum volume of container ["..id.."]")
    local v = unit["auto_detect_slots"]["container"][id].getMaxVolume()
    debug(v)
    return v
end

-- Get the mass of the empty container (in kg).
-- id: the id of the container
-- Return the mass of the container when empty
function containerGetSelfMass(id)
    id = toStr(id)
    debug("Getting mass of empty container ["..id.."]")
    local m = unit["auto_detect_slots"]["container"][id].getSelfMass()
    debug(m)
    return m
end

function containerIterate(func)
    debug("Iterating container table")
    tableIterate(unit["auto_detect_slots"]["container"], func)
end

--
-- DOOR UNIT
--

-- Get the number of doors.
function doorCount()
    debug("Getting the count of doors")
    return tableCount(unit["auto_detect_slots"]["door"])
end

-- Close a door.
-- id: door id (nil=all)
function doorClose(id)
    function op(id, unit, data)
        debug("Closing door ["..id.."]")
        unit.deactivate()
    end
    use(unit["auto_detect_slots"]["door"], id, op, nil)
end

-- Open a door.
-- id: door id (nil=all)
function doorOpen(id)
    function op(id, unit, data)
        debug("Opening door ["..id.."]")
        unit.activate()
    end
    use(unit["auto_detect_slots"]["door"], id, op, nil)
end

-- Get the state of a door.
-- id: door id
-- return the door state (1=open, 0=closed)
function doorGetState(id)
    id = toStr(id)
    debug("Getting state for door ["..id.."]")
    local st = unit["auto_detect_slots"]["door"][id].getState()
    return st
end

-- Toggle the state of a door.
-- id: door id (nil=all)
function doorToggle(id)
    function op(id, unit, data)
        debug("Toggling state for door ["..id.."]")
        unit.toggle()
    end
    use(unit["auto_detect_slots"]["door"], id, op, nil)
end

function doorIterate(func)
    debug("Iterating door table")
    tableIterate(unit["auto_detect_slots"]["door"], func)
end

--
-- LIGHT UNIT
--

-- Get the number of lights.
function lightCount()
    debug("Getting count of lights")
    return tableCount(unit["auto_detect_slots"]["light"])
end

-- Activate a light.
-- id: light id (nil=all)
function lightActivate(id)
    function op(id, unit, data)
        debug("Activating light ["..id.."]")
        unit.activate()
    end
    use(unit["auto_detect_slots"]["light"], id, op, nil)
end

-- Deactivate a light.
-- id: light id (nil=all)
function lightDeactivate(id)
    function op(id, unit, data)
        debug("Deactivating light ["..id.."]")
        unit.deactivate()
    end
    use(unit["auto_detect_slots"]["light"], id, op, nil)
end

-- Get the perceived brightness of a light.
-- id: light id
-- returns the brightness of the light
function lightGetBrightness(id)
    id = toStr(id)
    debug("Getting brightness for light ["..id.."]")
    local rgb = lightGetRGBColor(id)
    local br = math.sqrt((0.299 * rgb[1] * rgb[1]) + (0.587 * rgb[2] * rgb[2]) + (0.114 * rgb[3] * rgb[3]))
    return br
end

-- Get the RGB color of a light.
-- id: light id
-- returns the RGB color of the light
function lightGetRGBColor(id)
    id = toStr(id)
    debug("Getting RGB for light ["..id.."]")
    local rgb = unit["auto_detect_slots"]["light"][id].getRGBColor()
    return rgb
end

-- Get the state of a light.
-- id: light id
-- returns the state of the light (1=on, 0=off)
function lightGetState(id)
    id = toStr(id)
    debug("Getting state for light ["..id.."]")
    local st = unit["auto_detect_slots"]["light"][id].getState()
    return st
end

-- Set the RGB color of a light.
-- id: light id (nil=all)
-- rgb: the RGB color to set
function lightSetRGBColor(id, rgb)
    function op(id, unit, rgb)
        debug("Setting RGB for light ["..id.."]")
        unit.setRGBColor(rgb[1],rgb[2],rgb[3])
    end
    use(unit["auto_detect_slots"]["light"], id, op, rgb)
end

-- Toggle the state of a light.
-- id: light id (nil=all)
function lightToggle(id)
    function op(id, unit, data)
        debug("Toggling state for light ["..id.."]")
        unit.toggle()
    end
    use(unit["auto_detect_slots"]["light"], id, op, nil)
end

function lightIterate(func)
    debug("Iterating light table")
    tableIterate(unit["auto_detect_slots"]["light"], func)
end

--
-- SCREEN UNIT
--

-- Get the number of screens.
function screenCount()
    debug("Getting screen count")
    return tableCount(unit["auto_detect_slots"]["screen"])
end

-- Activate a screen.
-- id: screen index (nil=all)
function screenActivate(id)
    function op(id, unit, data)
        debug("Activating screen ["..id.."]")
        unit.activate()
    end
    use(unit["auto_detect_slots"]["screen"], id, op, nil)
end

-- Deactivate a screen.
-- id: screen id (nil=all)
function screenDeactivate(id)
    function op(id, unit, data)
        debug("Deactivating screen ["..id.."]")
        unit.deactivate()
    end
    use(unit["auto_detect_slots"]["screen"], id, op, nil)
end

-- Clear a screen.
-- id: screen id (nil=all)
function screenClear(id)
    function op(id, unit, data)
        debug("Clearing screen ["..id.."]")
        unit.clear()
    end
    use(unit["auto_detect_slots"]["screen"], id, op, nil)
end

-- Set a screen with HTML.
-- id: screen id (nil=all)
-- html: the HTML to set
function screenSetHTML(id, html)
    function op(id, unit, html)
        debug("Setting HTML on screen ["..id.."]")
        unit.setHTML(html)
    end
    use(unit["auto_detect_slots"]["screen"], id, op, html)
end

-- Set a screen with SVG.
-- id: screen id (nil=all)
-- svg: the SVG to set
function screenSetSVG(id, svg)
    function op(id, unit, svg)
        debug("Setting SVG on screen ["..id.."]")
        unit.setSVG(svg)
    end
    use(unit["auto_detect_slots"]["screen"], id, op, svg)
end

-- Set a screen with text.
-- id: screen id (nil=all)
-- text: the text to set
function screenSetText(id, text)
    function op(id, unit, text)
        debug("Setting TEXT on screen ["..id.."]")
        unit.setCenteredText(text)
    end
    use(unit["auto_detect_slots"]["screen"], id, op, text)
end

function screenIterate(func)
    debug("Iterating screen table")
    tableIterate(unit["auto_detect_slots"]["screen"], func)
end

--
-- SIGN UNIT
--

-- Get the number of signs.
function signCount()
    debug("Getting count of signs.")
    return tableCount(unit["auto_detect_slots"]["sign"])
end

-- Activate a sign.
-- id: sign id (nil=all)
function signActivate(id)
    function op(id, unit, data)
        debug("Activating sign ["..id.."]")
        unit.activate()
    end
    use(unit["auto_detect_slots"]["sign"], id, op, nil)
end

-- Deactivate a sign.
-- id: sign id (nil=all)
function signDeactivate(id)
    function op(id, unit, data)
        debug("Deactivating sign ["..id.."]")
        unit.deactivate()
    end
    use(unit["auto_detect_slots"]["sign"], id, op, nil)
end

-- Clear a sign.
-- id: sign id (nil=all)
function signClear(id)
    function op(id, unit, data)
        debug("Clearing sign ["..id.."]")
        unit.clear()
    end
    use(unit["auto_detect_slots"]["sign"], id, op, nil)
end

-- Set a sign with HTML.
-- id: sign id (nil=all)
-- html: the HTML to set
function signSetHTML(id, html)
    function op(id, unit, html)
        debug("Setting HTML on sign ["..id.."]")
        unit.setHTML(html)
    end
    use(unit["auto_detect_slots"]["sign"], id, op, html)
end

-- Set a sign with SVG.
-- id: sign id (nil=all)
-- svg: the SVG to set
function signSetSVG(id, svg)
    function op(id, unit, svg)
        debug("Setting SVG on sign ["..id.."]")
        unit.setSVG(svg)
    end
    use(unit["auto_detect_slots"]["sign"], id, op, svg)
end

-- Set a sign with text.
-- id: sign id (nil=all)
-- text: the text to set
function signSetText(id, text)
    function op(id, unit, text)
        debug("Setting TEXT on sign ["..id.."]")
        unit.setCenteredText(text)
    end
    use(unit["auto_detect_slots"]["sign"], id, op, text)
end

function signIterate(func)
    debug("Iterating sign table")
    tableIterate(unit["auto_detect_slots"]["sign"], func)
end
