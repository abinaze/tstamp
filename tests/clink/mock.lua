-- Test helper: runs shells/clink/tstamp.lua against a fake Clink so its logic
-- can be checked without Windows. Prints "ok - ..." and "FAIL - ..." lines.
--   lua mock.lua <repo root> <state dir> <proc dir>
local root, home, procdir = arg[1], arg[2], arg[3]

local function sh(cmd) local r = os.execute(cmd); return r == true or r == 0 end
local pass, fail = 0, 0
local function check(name, expected, actual)
  if expected == actual then pass = pass + 1; print("ok   - " .. name)
  else fail = fail + 1; print("FAIL - " .. name .. " (expected '" .. tostring(expected) .. "', got '" .. tostring(actual) .. "')") end
end

-- fake time
local T0, clock = 1794323250, 100.0     -- 2026-11-10 15:07:30 UTC
os.time = function() return T0 + math.floor(clock - 100.0) end
os.clock = function() return clock end

-- fake process list for tasklist, and fake pid
local alive = { [4000] = true }
local mypid = 4000
os.getpid = function() return mypid end
local real_popen = io.popen
io.popen = function(cmd)
  if cmd:find("echo %%time%%") then
    return { read = function() return "15:07:30.25\n" end, close = function() end }
  elseif cmd:find("tasklist") then
    local lines = {}
    for pid in pairs(alive) do lines[#lines + 1] = '"x.exe","' .. pid .. '","Console","1","1,000 K"' end
    local i = 0
    return { lines = function() return function() i = i + 1; return lines[i] end end, close = function() end }
  end
  return { read = function() return "" end, close = function() end }
end

-- fake file system calls
os.mkdir = function(p) return sh('mkdir -p "' .. p .. '"') end
os.rmdir = function(p) return sh('rmdir "' .. p .. '" 2>/dev/null') end
os.isdir = function(p) return sh('test -d "' .. p .. '"') end

local errorlevel = 0
os.geterrorlevel = function() return errorlevel end

-- fake Clink
local printed, on_begin, on_filter = {}, nil, nil
clink = {
  onbeginedit = function(f) on_begin = f end,
  onfilterinput = function(f) on_filter = f end,
  print = function(t) printed[#printed + 1] = t end,
}
local real_getenv = os.getenv
os.getenv = function(k) if k == "TSTAMP_HOME" then return home end return real_getenv(k) end

local function write(path, text) local f = io.open(path, "wb"); f:write(text); f:close() end
local function read(path) local f = io.open(path, "rb"); if not f then return nil end local s = f:read("*a"); f:close(); return s end
local function last() return printed[#printed] end
local function reset() printed = {} end

sh('mkdir -p "' .. home .. '"')
local M = dofile(root .. "/shells/clink/tstamp.lua")

-- formats
local us = 1794323250 * 1000000 + 123456
check("format 4", "2026-11-10 15:07:30.123", M.strftime(M.fmt_string("4"), us))
check("format 1", "15:07", M.strftime(M.fmt_string("1"), us))
check("format 5 uses the zone offset", "2026-11-10 15:07:30 +0000", M.strftime(M.fmt_string("5"), us))
check("custom format with 6N and %%", "123456 % Tue", M.strftime("%6N %% %a", us))
check("a number that is not a format is refused", nil, M.fmt_string("9"))

-- nothing happens while tracking is off
check("off: no change to the line", nil, on_filter("echo off"))
check("off: nothing printed", 0, #printed)
check("off: no session claimed", false, os.isdir(home .. "/sessions/T1"))

-- global on
write(home .. "/enabled", "boot=none\nsince=1\ngen=g1\n")
local wrapped = on_filter("echo hi")
check("global: the line gets the exit code reset", "(call ) & echo hi", wrapped)
check("global: START line", "[T1][2026-11-10 15:07:30.250] START: echo hi", printed[1])
check("global: session pid file", "4000\n", read(home .. "/sessions/T1/pid"))
check("global: session kind file", "windows\n", read(home .. "/sessions/T1/kind"))
clock = 100.5; errorlevel = 3
on_begin()
check("global: END line with exit code and duration", "[T1][2026-11-10 15:07:30.750] END: echo hi | EXIT=3 | DURATION=0.50s", printed[2])
local logtext = read(home .. "/logs/T1-4000.log")
check("log has START and END in the shared format", "1794323250250000\tT1\t4000\tSTART\t\t\techo hi\n1794323250750000\tT1\t4000\tEND\t3\t500000\techo hi\n", logtext)

-- lines that are never tracked
reset()
check("tstamp-a is not tracked", nil, on_filter("tstamp-a"))
check("exit is not tracked", nil, on_filter("exit"))
check("empty line is not tracked", nil, on_filter("   "))
check("tstamp format passes through to tstamp.cmd", nil, on_filter("tstamp export"))
check("nothing printed for those", 0, #printed)
on_begin()
check("no END without a START", 0, #printed)

-- tstamp stop stops this window only
reset()
check("tstamp stop is handled here", "rem", on_filter("tstamp stop"))
check("tstamp stop message 1", "Tracking stopped in this terminal. Other terminals are not affected.", printed[1])
check("tstamp stop message 2", "To stop everywhere, type: tstamp-a stop", printed[2])
reset()
on_filter("echo muted")
check("stopped window is not tracked", 0, #printed)
write(home .. "/enabled", "boot=none\nsince=2\ngen=g2\n")
on_filter("echo again")
check("a new tstamp-a switches it back on", "[T1][2026-11-10 15:07:30.750] START: echo again", printed[1])
on_begin()

-- tstamp-a stop stops a hand-enabled window
os.remove(home .. "/enabled")
write(home .. "/stopall", "n1\n")
reset()
check("local on: handled", "rem", on_filter("tstamp 2"))
check("local on: message", "Tracking enabled in this terminal (session T1).", printed[1])
check("local on: format shown", "Timestamp format: %H:%M:%S", printed[2])
reset()
on_filter("echo hand")
check("local on: tracked with format 2", "[T1][15:07:30] START: echo hand", printed[1])
on_begin()
write(home .. "/stopall", "n2\n")
reset()
on_filter("echo after stop all")
check("tstamp-a stop elsewhere stops it", 0, #printed)
reset()
check("tstamp with a number that is not a format passes through", nil, on_filter("tstamp 9"))
check("nothing printed for it", 0, #printed)

-- sessions: a dead window's label is reused, a live one's is not, bash ones are left alone
sh('rm -rf "' .. home .. '"/sessions "' .. home .. '"/logs "' .. home .. '"/enabled')
write(home .. "/enabled", "boot=none\nsince=1\ngen=g3\n")
sh('mkdir -p "' .. home .. '/sessions/T1" "' .. home .. '/sessions/T2" "' .. home .. '/sessions/T3"')
write(home .. "/sessions/T1/pid", "1111\n"); write(home .. "/sessions/T1/kind", "windows\n")   -- dead
write(home .. "/sessions/T2/pid", "999\n")                                                    -- bash, no kind
write(home .. "/sessions/T3/pid", "4000\n"); write(home .. "/sessions/T3/kind", "windows\n")  -- live
alive[4000] = true
package.loaded = package.loaded
M = dofile(root .. "/shells/clink/tstamp.lua")
reset()
on_filter("echo reuse")
check("dead windows session label is reused", "[T1][2026-11-10 15:07:30.250] START: echo reuse", printed[1])
check("bash session was left alone", "999\n", read(home .. "/sessions/T2/pid"))
check("live session was left alone", "4000\n", read(home .. "/sessions/T3/pid") and "4000\n")

print(string.format("\npassed=%d failed=%d", pass, fail))
os.exit(fail == 0 and 0 or 1)
