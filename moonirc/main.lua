require("socket")
require("std")

print("Loading config...")
dofile("config.lua")
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
REPLIES = {
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
    RPL_LUSERCLIENT = {251, ":There are %d users and %d invisible on %d servers"},
    RPL_LUSEROP = {252, "%d :operator(s) online"},
    RPL_LUSERUNKOWN = {253, "%d :unkown connections"},
    RPL_LUSERCHANNELS = {254, "%d :channels formed"},
    RPL_LUSERME = {255, ":I have %d clients and %d servers"},
    RPL_ADMINME = {256, "%s :Administrative info"},
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
    RPL_MOTD = {372, ":- %s"},
    RPL_ENDOFINFO = {374, ":End of /INFO list"},
    RPL_MOTDSTART = {375, ":- %s Message of the day - "},
    RPL_ENDOFMOTD = {376, ":End of /MOTD command"},
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
    ERR_UNKOWNMODE = {472, "%s :is unknown mode char to me"},
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

function send(user, code, ...)
    local s = ":"..REPLIES[code][1].." "
    s = s..string.format(REPLIES[code][2], ...).."\r\n"
    user.socket:send(s)
end

function parsecommand(command)
    assert(type(command) == "string", "bad argument #1 to 'parsecommand' (string expected, got "..type(command)..") ")
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
    if not arg or #arg < 1 then
        send(user, "ERR_NEEDMOREPARAMS", "PASS")
    elseif user.pass then
        send(user, "ERR_ALREADYREGISTERED")
    else
        user.pass = arg
    end
    return user
end
function irc_nick(user, arg)
    local arg = arg[1]
    if not arg or #arg < 1 then
        send(user, "ERR_NONICKNAMEGIVEN")
    elseif #arg > 9 or arg:gsub("[_%w]", ""):len() > 0 then
        send(user, "ERR_ERRONEUSNICKNAME", arg)
    elseif userexists(arg) then
        send(user, "ERR_NICKNAMEINUSER", arg)
    else
        user.name = arg
    end
    return user
end
function irc_user(user, arg)
    if not arg or #arg ~= 4 then
        send(user, "ERR_NEEDMOREPARAMS", "USER")
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
    send(user, "RPL_LUSERCLIENT", #USERS, 0, 1)
    send(user, "RPL_LUSEROP", 0)
    send(user, "RPL_LUSERCHANNELS", #CHANNELS)
    send(user, "RPL_LUSERME", #USERS, 0)
    send(user, "RPL_MOTDSTART", "moonirctest")
    for _,v in pairs(string.split(motd, "\n")) do
        send(user, "RPL_MOTD", v)
    end
    send(user, "RPL_ENDOFMOTD")
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
