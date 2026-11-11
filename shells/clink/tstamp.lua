-- TStamp integration for Command Prompt (cmd.exe) through Clink.
-- Needs Clink 1.7 or later (Lua 5.2). It shares ~/.tstamp (the global switch,
-- session labels and logs) with the Git Bash and PowerShell integrations, so
-- "tstamp export" merges all of them.
--
-- Clink loads this script into every Command Prompt window that runs Clink,
-- and also into short-lived helper processes (for example "clink set"), so
-- nothing here may claim a session or write a file when the script loads.

if not (clink and clink.onbeginedit and clink.onfilterinput) then
  print("tstamp: this Clink is too old for tracking (Clink 1.7 or later is needed).")
  return
end
if not (os.getpid and os.mkdir and os.isdir and os.rmdir and os.remove) then
  print("tstamp: this Clink lacks functions that tracking needs.")
  return
end

local SEP = package.config:sub(1, 1)
local function join(a, b) return a .. SEP .. b end

local TS = {
  home = os.getenv("TSTAMP_HOME"),
  sid = nil, log = nil, pid = nil,
  localon = false, localfmt = "", stopseen = "", mutedgen = "",
  pending = nil, start_us = 0, fmt = "",
  cal = nil, boot = nil,
}
if not TS.home or TS.home == "" then
  TS.home = join(os.getenv("USERPROFILE") or os.getenv("HOME") or ".", ".tstamp")
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function first_line(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a") or ""
  f:close()
  return (s:match("^[^\r\n]*"))
end

local function write_all(path, text)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(text)
  f:close()
  return true
end

-- ---------------------------------------------------------------- clock ----
-- Lua only knows whole seconds. "echo %time%" gives centiseconds, so the
-- script asks cmd.exe once, and then adds os.clock() to that moment.

local function calibrate()
  local out = ""
  local p = io.popen("echo %time%")
  if p then out = p:read("*a") or ""; p:close() end
  local clock = os.clock()
  local now = os.time()
  local sec, cs = out:match("%d+:%d+:(%d+)[%.,](%d+)")
  if sec then
    local cur = tonumber(os.date("%S", now))
    local diff = (tonumber(sec) - cur) % 60
    local base
    if diff == 0 then base = now elseif diff == 59 then base = now - 1 elseif diff == 1 then base = now + 1 end
    if base then
      TS.cal = { wall = base + tonumber("0." .. cs), clock = clock }
      return
    end
  end
  TS.cal = { wall = now, clock = clock }
end

local function now_us()
  if not TS.cal or os.clock() - TS.cal.clock > 1800 then calibrate() end
  local w = TS.cal.wall + (os.clock() - TS.cal.clock)
  return math.floor(w * 1000000 + 0.5)
end

-- --------------------------------------------------------------- format ----

local function tz_offset(sec)
  local l = os.date("*t", sec)
  local u = os.date("!*t", sec)
  u.isdst = l.isdst
  local diff = os.difftime(sec, os.time(u))
  local sign = diff < 0 and "-" or "+"
  diff = math.abs(diff)
  return string.format("%s%02d%02d", sign, math.floor(diff / 3600), math.floor((diff % 3600) / 60))
end

local function strftime(fmt, us)
  local sec = math.floor(us / 1000000)
  local fs = string.format("%06d", us - sec * 1000000)
  local function d(spec) return os.date(spec, sec) end
  local codes = {
    Y = function() return d("%Y") end, y = function() return d("%y") end,
    m = function() return d("%m") end, d = function() return d("%d") end,
    e = function() return string.format("%2d", tonumber(d("%d"))) end,
    H = function() return d("%H") end, M = function() return d("%M") end,
    S = function() return d("%S") end, b = function() return d("%b") end,
    B = function() return d("%B") end, a = function() return d("%a") end,
    A = function() return d("%A") end, j = function() return d("%j") end,
    T = function() return d("%H:%M:%S") end, F = function() return d("%Y-%m-%d") end,
    D = function() return d("%m/%d/%y") end, z = function() return tz_offset(sec) end,
    N = function() return fs .. "000" end, ["%"] = function() return "%" end,
  }
  local out, i = {}, 1
  while i <= #fmt do
    local c = fmt:sub(i, i)
    if c ~= "%" then
      out[#out + 1] = c
      i = i + 1
    else
      local two = fmt:sub(i + 1, i + 2)
      local k = fmt:sub(i + 1, i + 1)
      if two == "3N" then out[#out + 1] = fs:sub(1, 3); i = i + 3
      elseif two == "6N" then out[#out + 1] = fs; i = i + 3
      elseif k == "" then out[#out + 1] = "%"; i = i + 1
      elseif codes[k] then out[#out + 1] = codes[k](); i = i + 2
      else out[#out + 1] = "%" .. k; i = i + 2 end
    end
  end
  return table.concat(out)
end

local function fmt_string(id)
  if id == "1" then return "%H:%M" end
  if id == "2" then return "%H:%M:%S" end
  if id == "3" then return "%Y-%m-%d %H:%M:%S" end
  if id == "4" then return "%Y-%m-%d %H:%M:%S.%3N" end
  if id == "5" then return "%Y-%m-%d %H:%M:%S %z" end
  if id and id:find("%%") and not id:find("[\r\n]") then return id end
  return nil
end

local function config_format()
  local f = io.open(join(TS.home, "config"), "rb")
  if f then
    for line in (f:read("*a") or ""):gmatch("[^\r\n]+") do
      local v = line:match("^format=(.*)$")
      if v then f:close(); return v end
    end
    f:close()
  end
  return "4"
end

-- ----------------------------------------------------------- shared state --

local function boot_now()
  if TS.boot then return TS.boot end
  TS.boot = "none"
  local p = io.popen('powershell -NoProfile -NonInteractive -Command "[DateTimeOffset]::new((Get-CimInstance Win32_OperatingSystem).LastBootUpTime).ToUnixTimeSeconds()" 2>nul')
  if p then
    local n = (p:read("*a") or ""):match("(%d+)")
    p:close()
    if n then TS.boot = "ts:" .. n end
  end
  return TS.boot
end

local function same_boot(a, b)
  if a == "none" or b == "none" then return true end
  local x, y = a:match("^ts:(%d+)$"), b:match("^ts:(%d+)$")
  if x and y then return math.abs(tonumber(x) - tonumber(y)) <= 120 end
  return a == b
end

-- The gen value of the global flag when global tracking is on for this
-- boot ("legacy" for a flag written without one), otherwise nil.
local function global_gen()
  local f = io.open(join(TS.home, "enabled"), "rb")
  if not f then return nil end
  local text = f:read("*a") or ""
  f:close()
  local boot, gen = "", ""
  for line in text:gmatch("[^\r\n]+") do
    local k, v = line:match("^(%w+)=(.*)$")
    if k == "boot" then boot = v elseif k == "gen" then gen = v end
  end
  if boot ~= "none" and boot ~= "" and not same_boot(boot, boot_now()) then return nil end
  if gen ~= "" then return gen end
  return "legacy"
end

local function stopall()
  return first_line(join(TS.home, "stopall")) or ""
end

-- Same rules as the PowerShell integration.
local function enabled()
  if TS.localon then
    if stopall() == TS.stopseen then return true end
    TS.localon = false
    TS.localfmt = ""
  end
  local g = global_gen()
  if not g then return false end
  return g ~= TS.mutedgen
end

-- ------------------------------------------------------------- sessions ----

local function windows_pids()
  local set, count = {}, 0
  local p = io.popen("tasklist /NH /FO CSV 2>nul")
  if p then
    for line in p:lines() do
      local pid = line:match('^"[^"]*","(%d+)"')
      if pid then set[tonumber(pid)] = true; count = count + 1 end
    end
    p:close()
  end
  -- If our own process is missing, the list is unusable: treat all as alive.
  if not set[TS.pid] then return nil end
  return set
end

local function claim_session()
  if TS.sid then return true end
  local base = join(TS.home, "sessions")
  os.mkdir(TS.home)
  os.mkdir(base)
  os.mkdir(join(TS.home, "logs"))
  TS.pid = os.getpid()
  local pids, pids_read = nil, false
  for n = 1, 999 do
    local d = join(base, "T" .. n)
    local free = false
    if not os.isdir(d) then
      free = true
    else
      local kind = first_line(join(d, "kind"))
      if kind == "windows" then
        local p = tonumber(first_line(join(d, "pid")) or "") or 0
        if not pids_read then pids = windows_pids(); pids_read = true end
        if p > 0 and pids and not pids[p] then
          os.remove(join(d, "pid"))
          os.remove(join(d, "kind"))
          if os.rmdir(d) then free = true end
        end
      end
    end
    if free then
      os.mkdir(d)
      if write_all(join(d, "pid"), TS.pid .. "\n") and write_all(join(d, "kind"), "windows\n") then
        TS.sid = "T" .. n
        TS.log = join(join(TS.home, "logs"), "T" .. n .. "-" .. TS.pid .. ".log")
        return true
      end
    end
  end
  return false
end

local function log(ev, us, exit, dur, cmd)
  if not TS.log then return end
  local c = (cmd:gsub("[\t\r\n]", " "))
  local line = table.concat({
    string.format("%.0f", us), TS.sid, tostring(TS.pid), ev,
    exit == nil and "" or tostring(exit),
    dur == nil and "" or string.format("%.0f", dur), c,
  }, "\t") .. "\n"
  local f = io.open(TS.log, "ab")
  if f then f:write(line); f:close() end
end

-- ------------------------------------------------------------- the events --

local function say(text) clink.print(text) end

local function handle_tstamp(rest)
  rest = rest:gsub('^"(.*)"$', "%1")
  if rest == "stop" then
    TS.localon = false
    TS.localfmt = ""
    local g = global_gen()
    if g then TS.mutedgen = g end
    say("Tracking stopped in this terminal. Other terminals are not affected.")
    say("To stop everywhere, type: tstamp-a stop")
    return "rem"
  end
  if rest == "" or rest:match("^[1-5]$") or rest:find("%%") then
    if rest ~= "" and not fmt_string(rest) then
      say("tstamp: invalid format: " .. rest)
      return "rem"
    end
    if not claim_session() then
      say("tstamp: cannot create session state in " .. TS.home)
      return "rem"
    end
    TS.localfmt = rest
    TS.stopseen = stopall()
    TS.mutedgen = ""
    TS.localon = true
    local fmt = fmt_string(rest ~= "" and rest or config_format()) or fmt_string("4")
    say("Tracking enabled in this terminal (session " .. TS.sid .. ").")
    say("Timestamp format: " .. fmt)
    return "rem"
  end
  return nil -- every other tstamp command runs normally
end

-- Make the exit code honest: CMD built-in commands such as echo and cd leave
-- %ERRORLEVEL% as it was, so the line starts by setting it to 0.
local function wrap(text, word)
  if os.getenv("TSTAMP_CLINK_NOWRAP") == "1" then return nil end
  if os.getalias and os.getalias(word) then return nil end
  return "(call ) & " .. text
end

local function on_input(text)
  local t = trim(text)
  if t == "" then return nil end
  local word, rest = t:match("^(%S+)%s*(.*)$")
  local lower = word:lower()
  if lower == "tstamp" then return handle_tstamp(trim(rest)) end
  if lower == "tstamp-a" or lower == "exit" or lower == "logout" then return nil end
  if not enabled() then return nil end
  if not claim_session() then return nil end
  local fmt = fmt_string(TS.localfmt ~= "" and TS.localfmt or config_format()) or fmt_string("4")
  local us = now_us()
  TS.pending, TS.start_us, TS.fmt = t, us, fmt
  say(string.format("[%s][%s] START: %s", TS.sid, strftime(fmt, us), t))
  log("START", us, nil, nil, t)
  return wrap(text, word)
end

local function on_begin()
  if not TS.pending then return end
  local us = now_us()
  local code = 0
  if os.geterrorlevel then code = tonumber(os.geterrorlevel()) or 0 end
  local d = us - TS.start_us
  if d < 0 then d = 0 end
  local dur = string.format("%d.%02d", math.floor(d / 1000000), math.floor((d % 1000000) / 10000))
  say(string.format("[%s][%s] END: %s | EXIT=%d | DURATION=%ss", TS.sid, strftime(TS.fmt, us), TS.pending, code, dur))
  log("END", us, code, d, TS.pending)
  TS.pending = nil
end

clink.onfilterinput(on_input)
clink.onbeginedit(on_begin)

do
  local ok, v = pcall(function() return settings and settings.get and settings.get("cmd.get_errorlevel") end)
  if ok and v == false then
    print("tstamp: for exit codes, run once:  clink set cmd.get_errorlevel true")
  end
end

return { strftime = strftime, fmt_string = fmt_string, on_input = on_input, on_begin = on_begin, state = TS }
