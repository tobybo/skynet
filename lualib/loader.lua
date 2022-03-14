--(toby@2022-03-11)
-- %s 表示空白字符
-- %s+ 表示多个空白字符
-- %S+ 为上面的补集，表示所有非空格的字符
-- 这里之所以需要如此解析，是因为c传递过来的只有一个参数，为字符串
-- 如果是分开传递多个参数，则不需要解析，直接访问arg即可
local args = {}
for word in string.gmatch(..., "%S+") do
	table.insert(args, word)
end

SERVICE_NAME = args[1] --(toby@2022-03-11): "bootstrap"

local main, pattern

local err = {}
for pat in string.gmatch(LUA_SERVICE, "([^;]+);*") do
	local filename = string.gsub(pat, "?", SERVICE_NAME)
	local f, msg = loadfile(filename)
	if not f then
		table.insert(err, msg)
	else
		pattern = pat --(toby@2022-03-12): "./service/?.lua"
		main = f      --(toby@2022-03-12): loadfile("bootstrap.lua") 的返回值
		break
	end
end

if not main then
    --(toby@2022-03-12): 没有找到启动脚本，则打印错误信息并退出
	error(table.concat(err, "\n"))
end

LUA_SERVICE = nil
package.path , LUA_PATH = LUA_PATH
package.cpath , LUA_CPATH = LUA_CPATH

--(toby@2022-03-12): 获取脚本目录名, 匹配 以 "/" 结尾的最长字符串，且在源字符串中, "/" 之后还有1个以上非 (/ 或者 ？) 的字符
--  (.*/) 这个是匹配对象 "任意字符串/" 形式
--  [^/?]+ 表示所有非 (/ 或者 ？) 的字符1个或者多个
--  $ 在末尾表示该匹配结果必须包含字符串的末尾
--  "5.3手册: 在模式最后面加上符号 '$' 将使匹配过程锚定到字符串的结尾"
local service_path = string.match(pattern, "(.*/)[^/?]+$")

--(toby@2022-03-12): 不修改配置的话 默认为 nil 因为路径最后一层中存在 "?"
if service_path then
	service_path = string.gsub(service_path, "?", SERVICE_NAME)
	package.path = service_path .. "?.lua;" .. package.path
	SERVICE_PATH = service_path
else
	local p = string.match(pattern, "(.*/).+$")
	SERVICE_PATH = p
end

--(toby@2022-03-12): 执行预加载脚本 配置项 preload = "xxx"
if LUA_PRELOAD then
	local f = assert(loadfile(LUA_PRELOAD))
	f(table.unpack(args))
	LUA_PRELOAD = nil
end

main(select(2, table.unpack(args)))
