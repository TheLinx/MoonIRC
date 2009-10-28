require("socket")
require("std")

print("Starting MoonIRC Daemon... ")

soc = assert(socket.tcp(), "could not create socket")
assert(soc:bind('*', 6667), "could not bind socket")
assert(soc:listen(), "could not initiate socket")
assert(soc:settimeout(0), "could not set timeout")
assert(soc:setoption('keepalive', true), "could not set keepalive")
print("Listening for connections...")

USERS = {}
CHANNELS = {}
SERVERS = {}

function string.split(str, pat)
-- from http://lua-users.org/wiki/SplitJoin
   local t = {}
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function parsecommand(command)
    assert(type(command) == "string", "bad argument #1 to 'parsecommand' (string expected, got "..type(command)..") "..command or "")
    print("parsing command "..command)
    local fromuser = ""
    if command:sub(1,1) == ":" then
        local x = command:find(" ")
        fromuser = command:sub(2,x)
        command = command:sub(x+1)
    end
    local arguments = ""
    do
        local x = command:find(" ")
        arguments = command:sub(x+1)
        command = command:sub(1,x-1)
    end
    do
        local lastarg = ""
        if arguments:find(":") then
            local x = arguments:find(":")
            lastarg = arguments:sub(x+1)
            arguments = arguments:sub(1,x-2)
        end
        arguments = arguments:split(" ")
        if lastarg then arguments[#arguments+1] = lastarg end
    end
    return command,arguments,fromuser
end

function userexists(name)
    for _,user in pairs(USERS) do
        if user.name == name then
            return true
        end
    end
    return false
end

function irc_pass(user, arg)
    local arg = arg[1]
    if user.pass then
        user.socket:send(":You may not reregister")
    elseif not arg or #arg < 1 then
        user.socket:send("PASS :Not enough parameters")
    else
        user.pass = arg
    end
    return user
end
function irc_nick(user, arg)
    local arg = arg[1]
    if not arg or #arg < 1 then
        user.socket:send(":No nickname given")
    elseif #arg > 9 or arg:gsub("[_%w]", ""):len() > 0 then
        user.socket:send(arg.." :Erroneus nickname")
    elseif userexists(arg) then
        user.socket:send(arg.." :Nickname is already in use")
    else
        user.name = arg
    end
    return user
end
function irc_user(user, arg)
    if not arg or #arg ~= 4 then
        user.socket:send("USER :Not enough parameters")
    elseif user.name == arg[1] then
        user.hostname = arg[2]
        user.server = arg[3]
        user.realname = arg[4]
    end
    return user
end
function handshake(user)
    print("Connection initiated from "..user.ip)
    while true do
        local c,a = parsecommand(user.socket:receive("*l"))
        if c == "PASS" then
            user = irc_pass(user, a)
        elseif c == "NICK" then
            user = irc_nick(user, a)
        elseif c == "USER" then
            user = irc_user(user, a)
            break
        else
            error("user is a fag ("..c..","..unpack(a)..")")
        end
        USERS[user.ip] = user
    end
    USERS[user.ip] = user
    return true
end

while true do
    local ret,err = soc:accept()
    if ret then
        local ret_ip,ret_port = ret:getpeername()
        USERS[ret_ip] = {
            socket = ret,
            ip = ret_ip,
            port = ret_port
        }
        handshake(USERS[ret_ip])
    else
        assert(err == "timeout", err)
    end
    for _,v in pairs(USERS) do
        parsecommand(v.socket:receive("*l"))
    end
end
