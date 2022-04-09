local skynet = require "skynet"
local table = table
local string = string

skynet.dispatch("lua", function (session, addr, code, url, method, header, body)
    LOG("i am slave, received a msg, session,%s, addr,%s", session, addr)
    local msg
    if code == 200 then
        local tmp = {}
        if header.host then
            table.insert(tmp, string.format("host: %s", header.host))
        end
        local path, query = urllib.parse(url)
        table.insert(tmp, string.format("path: %s", path))
        if query then
            local q = urllib.parse_query(query)
            for k, v in pairs(q) do
                table.insert(tmp, string.format("query: %s= %s", k,v))
            end
        end
        table.insert(tmp, "-----header----")
        for k,v in pairs(header) do
            table.insert(tmp, string.format("%s = %s",k,v))
        end
        table.insert(tmp, "-----body----\n" .. body)
        msg = table.concat(tmp,"\n")
    end
    skynet.ret(skynet.pack(code, msg))
end)

skynet.start(function()
    skynet.send(".cslave", "lua", "REGISTER", "game", skynet.self())
end)

