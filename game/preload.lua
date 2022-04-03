-- This file will execute before every lua service start
-- See config

--print("PRELOAD", ...)
package.path = "./game/?.lua;"..package.path
require("tools/tool_log")


