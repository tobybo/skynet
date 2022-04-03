--==============================================================================
-- 工具函数库
-- Author: toby
-- Desc:
--	   在 preload 中加载到全局表
-- History:
--     2022-03-31 11:35:54 Updated
-- Copyright © 2022 IGG SINGAPORE PTE. LTD. All rights reserved.
--==============================================================================

local c = require "skynet.core"

local log = c.error

local base_str = ")%s%s [%s], %s"

local COLOR = {
    BLACK   = 30,
    RED     = 31,
    GREEN   = 32,
    YELLOW  = 33,
    BLUE    = 34,
    FUCHSIN = 35, -- 品红
    CYAN    = 36, -- 青色 蓝绿色
}

LOG = function(format_str, ...)
    local str = string.format(base_str, COLOR.CYAN, "LOG", SERVICE_NAME, format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end

INFO = function(format_str, ...)
    local str = string.format(base_str, COLOR.GREEN, "INFO", SERVICE_NAME, format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end

WARN = function(format_str, ...)
    local str = string.format(base_str, COLOR.YELLOW, "WARN", SERVICE_NAME, format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end

ERROR = function(format_str, ...)
    local str = string.format(base_str, COLOR.RED, "ERROR", SERVICE_NAME, format_str)
    if select("#", ...) > 0 then
        str = string.format(str, ...)
    end
    log(str)
end
