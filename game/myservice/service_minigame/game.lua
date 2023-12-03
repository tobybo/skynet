local skynet = require "skynet"
local table = table
local string = string

local handler = {}
handler.regist = function(msg)
    local account = msg:sub(1,6)
    local passward = msg:sub(7,14)
    return 0, string.format("welcome, %s, your passward is,%s", account, passward)
end

skynet.dispatch("lua", function (session, addr, msg, msg_type)
    LOG("i am slave, received a msg, session,%s, addr,%s, type,%s, msg,%s", session, addr, msg_type, msg)
    local proto_name_len = tonumber(msg:sub(1,2))
    local proto_name = msg:sub(3, proto_name_len + 3 - 1)
    local rpc = handler[proto_name]
    local code, ret_msg
    if not rpc then
        code = 1
        ret_msg = "nil rpc"
    else
        code, ret_msg = rpc(msg:sub(proto_name_len + 3))
    end
    INFO("i am slave, rpc done, len,%s, name,%s, code,%s, msg,%s", proto_name_len, proto_name, code, ret_msg)
    skynet.ret(skynet.pack(code, ret_msg))
end)

skynet.start(function()
    skynet.send(".cslave", "lua", "REGISTER", "game", skynet.self())
end)
