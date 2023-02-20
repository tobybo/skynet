local skynet = require "skynet"
local socket = require "skynet.socket"
local service = require "skynet.service"
local websocket = require "http.websocket"

local handle = {}
local MODE = ...

if MODE == "agent" then

    game_svr_addr = game_svr_addr

    function handle.connect(id)
        INFO("ws connect from: " .. tostring(id))
    end

    function handle.handshake(id, header, url)
        local addr = websocket.addrinfo(id)
        INFO("ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
        INFO("----header-----")
        for k,v in pairs(header) do
            INFO(k,v)
        end
        INFO("--------------")
    end

    function handle.message(id, msg, msg_type)
        assert(msg_type == "binary" or msg_type == "text")
        INFO("ws message, id,%s, msg,%s, msg_type,%s", id, msg, msg_type)

        LOG("find game_addr from slave begin, game_svr_addr,%s", game_svr_addr)
        if not game_svr_addr then
            game_svr_addr = skynet.call(".cslave", "lua", "QUERYNAME", "game")
        end
        LOG("find game_addr from slave, game_addr,%s", game_svr_addr)
        local code, ret_msg = skynet.call(game_svr_addr, "lua", msg, msg_type)
        INFO("i am master, call game back, code,%s, ret_msg,%s", code, ret_msg)
        websocket.write(id, code..ret_msg)
    end

    function handle.ping(id)
        INFO("ws ping from: " .. tostring(id) .. "\n")
    end

    function handle.pong(id)
        INFO("ws pong from: " .. tostring(id))
    end

    function handle.close(id, code, reason)
        INFO("ws close from: " .. tostring(id), code, reason)
    end

    function handle.error(id)
        INFO("ws error from: " .. tostring(id))
    end

    skynet.start(function ()
        skynet.dispatch("lua", function (_,_, id, protocol, addr)
            local ok, err = websocket.accept(id, handle, protocol, addr)
            if not ok then
                INFO(err)
            end
        end)
    end)

else
    local function simple_echo_client_service(protocol)
        local skynet = require "skynet"
        local websocket = require "http.websocket"
        local url = string.format("%s://128.0.0.1:9948/test_websocket", protocol)
        local ws_id = websocket.connect(url)
        while true do
            local msg = "hello world!"
            websocket.write(ws_id, msg)
            INFO(">: " .. msg)
            local resp, close_reason = websocket.read(ws_id)
            INFO("<: " .. (resp and resp or "[Close] " .. close_reason))
            if not resp then
                INFO("echo server close.")
                break
            end
            websocket.ping(ws_id)
            skynet.sleep(100)
        end
    end

    skynet.start(function ()
        local agent = {}
        for i= 1, 20 do
            agent[i] = skynet.newservice(SERVICE_NAME, "agent")
        end
        local balance = 1
        local protocol = "ws"
        local id = socket.listen("0.0.0.0", 8001)
        ERROR("Listen websocket port 8001 protocol:%s", protocol)
        socket.start(id, function(id, addr)
            INFO("accept client socket_id: %s addr:%s", id, addr)
            skynet.send(agent[balance], "lua", id, protocol, addr)
            balance = balance + 1
            if balance > #agent then
                balance = 1
            end
        end)
        -- test echo client
        --service.new("websocket_echo_client", simple_echo_client_service, protocol)
    end)
end
