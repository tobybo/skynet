-- This file will execute before every lua service start
-- See config

--print("PRELOAD", ...)

local c = require "skynet.core"

local log = c.error

local base_str = ")%s%s %s"

LOG = function(format_str, ...)
    local str = string.format(base_str, 36, "LOG", format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end

INFO = function(format_str, ...)
    local str = string.format(base_str, 37, "INFO", format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end

WARN = function(format_str, ...)
    local str = string.format(base_str, 33, "WARN", format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end

ERROR = function(format_str, ...)
    local str = string.format(base_str, 31, "ERROR", format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end
