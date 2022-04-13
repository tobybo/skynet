local skynet = require "skynet"
local table = table
local string = string
require "skynet.manager"

skynet.register_protocol({
    name = "gate",
    id = skynet.PTYPE_TEXT,
    pack = function(...) return ... end,
    unpack = skynet.unpack,
})

skynet.start(function()
    local client_gate = skynet.launch("gate", "A", "!", "0.0.0.0:8001", "0", "10000")
    skynet.name(".client_gate", client_gate)
    local svr_gate = skynet.launch("gate", "A", "!", "0.0.0.0:8002", "0", "10")
    skynet.name(".svr_gate", svr_gate)
    skynet.send(client_gate, "gate", "broker_http .svr_gate")
    skynet.send(svr_gate, "gate", "broker .client_gate")
    INFO("client_gate: %d, svr_gate: %d", client_gate, svr_gate)
    skynet.exit()
end)
