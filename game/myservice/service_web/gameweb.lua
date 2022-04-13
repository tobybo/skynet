local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

local mode, protocol = ...
protocol = protocol or "http"

if mode == "agent" then

local function response(id, write, ...)
	local ok, err = httpd.write_response(write, ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end


local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
	if protocol == "http" then
		return {
			init = nil,
			close = nil,
			read = sockethelper.readfunc(fd),
			write = sockethelper.writefunc(fd),
		}
	elseif protocol == "https" then
		local tls = require "http.tlshelper"
		if not SSLCTX_SERVER then
			SSLCTX_SERVER = tls.newctx()
			-- gen cert and key
			-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
			local certfile = skynet.getenv("certfile") or "./server-cert.pem"
			local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
			print(certfile, keyfile)
			SSLCTX_SERVER:set_cert(certfile, keyfile)
		end
		local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
		return {
			init = tls.init_responsefunc(fd, tls_ctx),
			close = tls.closefunc(tls_ctx),
			read = tls.readfunc(fd, tls_ctx),
			write = tls.writefunc(fd, tls_ctx),
		}
	else
		error(string.format("Invalid protocol: %s", protocol))
	end
end

local function wrap_int(val)
    local str = ""
    for i = 1, 4 do
        str = str .. string.char((val >> ((i - 1) * 8)) & 0xFF)
    end
    return str
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)
        local size, sid
        local interface = gen_interface(protocol, id)
        if interface.init then
            interface.init()
        end
        -- local readbytes = sockethelper.readfunc(id)
        local writebytes = sockethelper.writefunc(id)
        while true do
            -- size = nil
            -- while (not size) do
            --     INFO("prepare to read size, id,%s", id)
            --     --size = readbytes(4)
            --     size = tonumber(readbytes(4))
            -- end
            -- INFO("prepare to read sid, id,%s, size,%s", id, size)
            -- while (not sid or sid <= 0) do
            --     sid = tonumber(readbytes(4))
            -- end
            -- INFO("prepare to read content, id,%s, size,%s, sid,%s", id, size, sid)

            -- limit request body size to 8192 (you can pass nil to unlimit)
            INFO("prepare to receive http msg, id,%s", id)
            local code, url, method, header, body, size, sid = httpd.read_request(interface.read, 8192, true)
            INFO("receive http msg, code,%s, url,%s, size,%s, sid,%s", code, url, size, sid)
            if code then
                if code ~= 200 then
                    response(id, interface.write, code)
                else
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
                    writebytes(wrap_int(sid))
                    response(id, interface.write, code, table.concat(tmp,"\n"))
                end
            else
                if url == sockethelper.socket_error then
                    skynet.error("socket closed")
                else
                    skynet.error(url)
                end
                break
            end
        end
		socket.close(id)
		if interface.close then
			interface.close()
		end
	end)
end)

else

skynet.start(function()
	local protocol = "http"
	local agent = skynet.newservice(SERVICE_NAME, "agent", protocol)
    local svr_gate_id = socket.open("127.0.0.1:8002")
    INFO("connect svr_gate_id completed, svr_gate_id,%s", svr_gate_id)
    skynet.send(agent, "lua", svr_gate_id)
    --skynet.exit()
end)

end
