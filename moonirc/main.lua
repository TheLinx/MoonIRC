require("socket")
require("copas")
require("printr")

io.write("Loading config... ") io.flush()
dofile("config.lua")
print("done!")

socket = assert(socket.tcp(), "could not create socket")
assert(socket:bind('*', serverport), "could not bind socket")
assert(socket:listen(), "could not initiate socket")
assert(socket:settimeout(0), "could not set timeout")
assert(socket:setoption('keepalive', true), "could not set keepalive")

function printf(s, ...)
    local g,o = pcall(function(t, ...) return string.format(t, ...) end, s, ...)
    return print((g and o) or s)
end

CREATED = os.date("%c")
VERSION = "MoonIRC-ALPHA"
USERS = {}
CHANNELS = {}
SERVERS = {}
REPLIES = {
    CMD_PONG = {"PONG", "%s :%s"},
    RPL_WELCOME = {001, "%s :Welcome to the %s %s"},
    -- :Welcome to the <servername> <nickname>
    RPL_YOURHOST = {002, "%s :Your host is %s, running version %s"},
    RPL_CREATED = {003, "%s :This server was created %s"},
    RPL_MYINFO = {004, "%s %s %s %s %s"},
    -- <target nick> <servername> <version> <available user modes> <available channel modes>
    RPL_TRACELINK = {200, "Link %s %s %s"},
    -- Link <version & debug level> <destination> <next server>
    RPL_TRACECONNECTING = {201, "Try. %s %s"},
    -- Try. <class> <server>
    RPL_TRACEHANDSHAKE = {202, "H.S. %s %s"},
    -- H.S. <class> <server>
    RPL_TRACEUNKNOWN = {203, "???? %s %s"},
    -- ???? <class> [<client IP address in dot form>]
    RPL_TRACEOPERATOR = {204, "Oper %s %s"},
    -- Oper <class> <nick>
    RPL_TRACEUSER = {205, "User %s %s"},
    -- User <class> <nick>
    RPL_TRACESERVER = {206, "Server %s %sS %sC %s %s@%s"},
    -- Serv <class> <int>S <int>C <server> <nick!user|*!*>@<host|server>
    RPL_TRACENEWTYPE = {208, "%s 0 %s"},
    -- <newtype> 0 <client name>
    RPL_STATSLINKINFO = {211, "%s %s %s %s %s %s %s"},
    -- <linkname> <sendq> <sent messages> sent bytes> <received messages> <received bytes> <time open>
    RPL_STATSCOMMANDS = {212, "%s %s"},
    -- <command> <count>
    RPL_STATSCLINE = {213, "C %s * %s %s %s"},
    -- C <host> * <name> <port> <class>
    RPL_STATSNLINE = {214, "N %s * %s %s %s"},
    RPL_STATSILINE = {215, "I %s * %s %s %s"},
    RPL_STATSKLINE = {216, "K %s * %s %s %s"},
    RPL_STATSYLINE = {218, "Y %s %s %s %s"},
    -- Y <class> <ping frequency> <connect frequency> <max sendq>
    RPL_ENDOFSTATS = {219, "%s :End of /STATS report"},
    RPL_UMODEIS = {221, "%s"},
    RPL_STATSLLINE = {241, "%s * %s %s"},
    -- L <hostmask> * <servername> <maxdepth>
    RPL_STATSUPTIME = {242, "Server Up %d days %d:%d:%d"},
    RPL_STATSOLINE = {243, "%s * %s"},
    RPL_STATSHLINE = {244, "%s * %s"},
    -- H <mask> * <name>
    RPL_LUSERCLIENT = {251, "%s :There are %d users and %d invisible on %d servers"},
    RPL_LUSEROP = {252, "%s %d :operator(s) online"},
    RPL_LUSERUNKOWN = {253, "%s %d :unkown connections"},
    RPL_LUSERCHANNELS = {254, "%s %d :channels formed"},
    RPL_LUSERME = {255, "%s :I have %d clients and %d servers"},
    RPL_ADMINME = {256, "%s %s :Administrative info"},
    RPL_ADMINLOC1 = {257, ":%s"},
    -- city, state, country
    RPL_ADMINLOC2 = {258, ":%s"},
    -- university and department
    RPL_ADMINEMAIL = {259, ":%s"},
    RPL_TRACELOG = {261, "File %s %s"},
    -- File <logfile> <debug level>
    RPL_AWAY = {301, "%s :%s"},
    RPL_USERHOST = {302, ":%s%s = %s%s"},
    -- <nick>['*' if op] '=' <'+'|'-' away or not><hostname>
    RPL_ISON = {303, ":%s"},
    -- <nick>
    RPL_UNAWAY = {305, ":You are no longer marked as being away"},
    RPL_NOWAWAY = {306, ":You have been marked as being away"},
    RPL_WHOISUSER = {311, "%s %s %s * :%s"},
    -- <nick> <user> <host> * :<real name>
    RPL_WHOISSERVER = {312, "%s %s :%s"},
    -- <nick> <server> :<server info>
    RPL_WHOISOPERATOR = {313, "%s :is an IRC operator"},
    RPL_WHOWASUSER = {314, "%s %s %s * :%s"},
    -- <nick> <user> <host> * :<real name>
    RPL_ENDOFWHO = {315, "%s :End of /WHO list"},
    RPL_WHOISIDLE = {317, "%s %d :seconds idle"},
    RPL_ENDOFWHOIS = {318, "%s :End of /WHOIS list"},
    RPL_WHOISCHANNELS = {319, "%s :%s%s "},
    -- <nick> :{[@|+]<channel><space>}
    RPL_LISTSTART = {321, "Channel :Users  Name"},
    RPL_LIST = {322, "%s %s :%s"},
    -- <channel> <# visible> :<topic>
    RPL_ENDOFLIST = {323, ":End of /LIST"},
    RPL_CHANNELMODEIS = {324, "%s %s %s"},
    -- <channel> <mode> <mode params>
    RPL_NOTOPIC = {331, "%s :No topic is set"},
    RPL_TOPIC = {332, "%s :%s"},
    RPL_INVITING = {341, "%s %s"},
    -- <channel> <nick>
    RPL_SUMMONING = {342, "%s :Summoning user to IRC"},
    RPL_VERSION = {351, "%s.%s %s :%s"},
    -- <version>.<debuglevel> <server> :<comments>
    RPL_WHOREPLY = {352, "%s %s %s %s %s %s%s%s :%s %s"},
    -- <channel> <user> <host> <server> <nick> <H|G>[*][@|+] :<hopcount> <real name>
    RPL_NAMREPLY = {353, "%s :%s"},
    -- <channel> :[[@|+]<nick> [[@|+]<nick> [...]]]
    RPL_LINKS = {364, "%s %s :%s %s"},
    -- <mask> <server> :<hopcount> <server info>
    RPL_ENDOFLINKS = {365, "%s :End of /LINKS list"},
    RPL_ENDOFNAMES = {366, "%s :End of /NAMES list"},
    RPL_BANLIST = {367, "%s %s"},
    -- <channel> <banid>
    RPL_ENDOFBANLIST = {368, "%s :End of channel ban list"},
    RPL_ENDOFWHOWAS = {369, "%s :End of WHOWAS"},
    RPL_INFO = {371, ":%s"},
    RPL_MOTD = {372, "%s :- %s"},
    RPL_ENDOFINFO = {374, "%s :End of /INFO list"},
    RPL_MOTDSTART = {375, "%s :- %s Message of the day - "},
    RPL_ENDOFMOTD = {376, "%s :End of /MOTD command"},
    RPL_YOUREOPER = {381, ":You are now an IRC operator"},
    RPL_REHASHING = {382, "%s :Rehashing"},
    RPL_TIME = {391, "%s :%s"},
    -- <server> :<string showing server's local time>
    RPL_USERSSTART = {392, ":UserID   Terminal  Host"},
    RPL_USERS = {393, "%s %s %s"},
    RPL_ENDOFUSERS = {394, ":End of users"},
    RPL_NOUSERS = {395, ":Nobody logged in"},
    ERR_NOSUCHNICK = {401, "%s :No such nick/channel"},
    ERR_NOSUCHSERVER = {402, "%s :No such server"},
    ERR_NOSUCHCHANNEL = {403, "%s :No such channel"},
    ERR_CANNOTSENDTOCHAN = {404, "%s :Cannot send to channel"},
    ERR_TOOMANYCHANNELS = {405, "%s :You have joined too many channels"},
    ERR_WASNOSUCHNICK = {406, "%s :There was no such nickname"},
    ERR_TOOMANYTARGETS = {407, "%s :Duplicate recipients. No message delivered"},
    ERR_NOORIGIN = {409, ":No origin specified"},
    ERR_NORECIPIENT = {411, ":No recipient given (%s)"},
    ERR_NOTEXTTOSEND = {412, ":No text to send"},
    ERR_NOTOPLEVEL = {413, "%s :No toplevel domain specified"},
    ERR_WILDTOPLEVEL = {414, "%s :Wildcard in toplevel domain"},
    ERR_UNKNOWNCOMMAND = {421, "%s :Unknown command"},
    ERR_NOMOTD = {422, ":MOTD File is missing"},
    ERR_NOADMININFO = {423, "%s :No administrative info available"},
    ERR_FILEERROR = {424, ":File error doing %s on %s"},
    ERR_NONICKNAMEGIVEN = {431, ":No nickname given"},
    ERR_ERRONEUSNICKNAME = {432, "%s :Erroneus nickname"},
    ERR_NICKNAMEINUSE = {433, "%s :Nickname is already in use"},
    ERR_NICKCOLLISION = {436, "%s :Nickname collision KILL"},
    ERR_USERNOTINCHANNEL = {441, "%s %s :They aren't on that channel"},
    ERR_NOTONCHANNEL = {442, "%s :You're not on that channel"},
    ERR_USERONCHANNEL = {443, "%s %s :is already on channel"},
    ERR_NOLOGIN = {444, "%s :User not logged in"},
    ERR_SUMMONDISABLED = {445, ":SUMMON has been disabled"},
    ERR_USERSDISABLED = {446, ":USERS has been disabled"},
    ERR_NOTREGISTERED = {451, ":You have not registered"},
    ERR_NEEDMOREPARAMS = {461, "%s :Not enough parameters"},
    ERR_ALREADYREGISTERED = {462, ":You may not reregister"},
    ERR_NOPERMFORHOST = {463, ":Your host isn't among the privileged"},
    ERR_PASSWDMISMATCH = {464, ":Password incorrect"},
    ERR_YOUREBANNEDCREEP = {465, ":You are banned from this server"},
    ERR_KEYSET = {467, "%s :Channel key already set"},
    ERR_CHANNELISFULL = {471, "%s :Cannot join channel (+l)"},
    ERR_UNKNOWNMODE = {472, "%s %s :is unknown mode char to me"},
    ERR_INVITEONLYCHAN = {473, "%s :Cannot join channel (+i)"},
    ERR_BANNEDFROMCHAN = {474, "%s :Cannot join channel (+b)"},
    ERR_BADCHANNELKEY = {475, "%s :Cannot join channel (+k)"},
    ERR_NOPRIVILEGES = {481, ":Permission Denied- You're not an IRC operator"},
    ERR_CHANOPRIVSNEEDED = {482, "%s :You're not channel operator"},
    ERR_CANTKILLSERVER = {483, ":You cant kill a server!"},
    ERR_NOOPERHOST = {491, ":No O-lines for your host"},
    ERR_UMODEUNKNOWNFLAG = {501, ":Unknown MODE flag"},
    ERR_USERSDONTMATCH = {502, ":Cant change mode for other users"}
}

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

-- UTILITY FUNCTIONS --
function format(code, ...)
    if tonumber(REPLIES[code][1]) then
        cmd = string.format("%0.3d", REPLIES[code][1])
    else
        cmd = REPLIES[code][1]
    end
    arg = string.format(REPLIES[code][2], ...)
    return string.format(":%s %s %s", serverhost, cmd, arg)
end
function send(soc, ip, s)
    printf("<-- (%s) %s", ip, s)
    soc:send(s.."\r\n")
end
function parsecommand(user, command)
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
    if arguments:sub(1,1) == ":" then
        arguments = arguments:sub(2)
    end
    do
        local lastarg
        if arguments:find(":") then
            local x = arguments:find(":")
            lastarg = arguments:sub(x+1)
            arguments = arguments:sub(1,x-2)
        end
        arguments = arguments:split(" ")
        if lastarg then arguments[#arguments+1] = lastarg end
    end
    --printf(" - got command %s arguments %s", tostring(command), tostring(arguments))
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
function usermode(act, mode)
    if act == "add" then
        
    elseif act == "del" then
        
    elseif act == "chk" then
        return (user.mode:find(mode) ~= nil)
    end
end

-- IRC COMMANDS --
command = {}
function command.pass(user, arg)
    do return format("ERR_NEEDMOREPARAMS", "PASS") end
    local arg = arg[1]
    if not arg or #arg < 1 then
        return format("ERR_NEEDMOREPARAMS", "PASS")
    elseif user.pass then
        return format("ERR_ALREADYREGISTERED")
    end
    USERS[user.adress].pass = arg
end
function command.nick(user, arg)
    local arg = arg[1]
    if not arg or #arg < 1 then
        return format("ERR_NONICKNAMEGIVEN")
    elseif #arg > 9 or arg:gsub("[_%w]", ""):len() > 0 then
        return format("ERR_ERRONEUSNICKNAME", arg)
    elseif userexists(arg) then
        return format("ERR_NICKNAMEINUSER", arg)
    end
    USERS[user.adress].name = arg
end
function command.user(user, arg)
    if not arg or #arg ~= 4 then
        return format("ERR_NEEDMOREPARAMS", "USER")
    end
    USERS[user.adress].username = arg[1]
    USERS[user.adress].realname = arg[4]
end
function command.mode(user, arg)
    return format("ERR_UNKNOWNMODE", user.name, arg[2]:gsub("%+", ""))
end
function command.ping(user, arg)
    return format("CMD_PONG", serverhost, arg[2] or "")
end
function command.quit(user)
    USERS[user.adress] = nil
end

command_mt = {
    __index = function(tbl, key)
        return rawget(tbl,key) or function(user)
            return format("ERR_UNKNOWNCOMMAND", key)
        end
    end
}
setmetatable(command, command_mt)

function connectionHandler(soc)
    local soc = copas.wrap(soc)
    while true do
        local data = soc:receive()
        if data then
            local u_ip,u_port = soc.socket:getpeername()
            printf("--> (%s) %s", u_ip, data)
            if not USERS[u_ip] then
                USERS[u_ip] = {
                    adress = u_ip,
                    hostname = "on.nimp.org", -- protip: don't go here
                    mode = "",
                    name = "Guest-"..#USERS,
                    new = true
                }
            end
            local user = USERS[u_ip]
            local c,a,f = false,false,false
            c,a,f = parsecommand(user, data)
            if c then
                c = c:lower()
                local s = command[c](user, a)
                if s then
                    send(soc, u_ip, s)
                end
            end
            if USERS[u_ip] and USERS[u_ip].new and USERS[u_ip].username then
                printf("<-- (%s) shaking hands", user.adress)
                send(soc, u_ip, format("RPL_WELCOME", user.name, servername, user.name))
                send(soc, u_ip, format("RPL_YOURHOST", user.name, serverhost, VERSION))
                send(soc, u_ip, format("RPL_CREATED", user.name, CREATED))
                send(soc, u_ip, format("RPL_LUSERCLIENT", user.name, #USERS, 0, 1))
                send(soc, u_ip, format("RPL_LUSEROP", user.name, 0))
                send(soc, u_ip, format("RPL_LUSERCHANNELS", user.name, #CHANNELS))
                send(soc, u_ip, format("RPL_LUSERME", user.name, #USERS, 0))
                send(soc, u_ip, format("RPL_MOTDSTART", user.name, servername))
                for _,v in pairs(string.split(motd, "\n")) do
                    send(soc, u_ip, format("RPL_MOTD", user.name, v))
                end
                send(soc, u_ip, format("RPL_ENDOFMOTD", user.name))
                USERS[u_ip].new = false
            end
        end
    end
end

print("GURREN LAGANN, SPIN ON")
copas.addserver(socket, connectionHandler)
copas.loop()
