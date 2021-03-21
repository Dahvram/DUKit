-- DUKit Version: 0.1.0

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
        local errmsg = errmsg or "ERROR: Tested condition was false!"
        err(errmsg, True)
    end
end
