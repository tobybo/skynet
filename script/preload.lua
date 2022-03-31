-- This file will execute before every lua service start
-- See config

--print("PRELOAD", ...)
package.path = "./script/?.lua;"..package.path
require("tools/tool_log")


