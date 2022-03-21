#include "skynet.h"

#include "skynet_imp.h"
#include "skynet_env.h"
#include "skynet_server.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <signal.h>
#include <assert.h>

static int
optint(const char *key, int opt) {
	const char * str = skynet_getenv(key);
	if (str == NULL) {
		char tmp[20];
		sprintf(tmp,"%d",opt);
		skynet_setenv(key, tmp);
		return opt;
	}
	return strtol(str, NULL, 10);
}

static int
optboolean(const char *key, int opt) {
	const char * str = skynet_getenv(key);
	if (str == NULL) {
		skynet_setenv(key, opt ? "true" : "false");
		return opt;
	}
	return strcmp(str,"true")==0;
}

static const char *
optstring(const char *key,const char * opt) {
	const char * str = skynet_getenv(key);
	if (str == NULL) {
		if (opt) {
			skynet_setenv(key, opt);
			opt = skynet_getenv(key);
		}
		return opt;
	}
	return str;
}

static void
_init_env(lua_State *L) {
	lua_pushnil(L);  /* first key */
	while (lua_next(L, -2) != 0) {
		int keyt = lua_type(L, -2);
		if (keyt != LUA_TSTRING) {
			fprintf(stderr, "Invalid config table\n");
			exit(1);
		}
		const char * key = lua_tostring(L,-2);
		if (lua_type(L,-1) == LUA_TBOOLEAN) {
			int b = lua_toboolean(L,-1);
			skynet_setenv(key,b ? "true" : "false" );
		} else {
			const char * value = lua_tostring(L,-1);
			if (value == NULL) {
				fprintf(stderr, "Invalid config table key = %s\n", key);
				exit(1);
			}
			skynet_setenv(key,value);
		}
		lua_pop(L,1);
	}
	lua_pop(L,1);
}

int sigign() {
	struct sigaction sa;
	sa.sa_handler = SIG_IGN;
	sa.sa_flags = 0;
	sigemptyset(&sa.sa_mask);
	sigaction(SIGPIPE, &sa, 0);
	return 0;
}

static const char * load_config = "\
	local result = {}\n\
\n\
    --(toby@2022-03-09): 将配置中的 $XXX 转化为环境变量XXX的值 \n\
	local function getenv(name) return assert(os.getenv(name), [[os.getenv() failed: ]] .. name) end\n\
\n\
    --(toby@2022-03-09): 获取文件分隔符 linux上是 正斜杠 \n\
	local sep = package.config:sub(1,1)\n\
\n\
    --(toby@2022-03-09): 设置当前路径 \n\
	local current_path = [[.]]..sep\n\
\n\
    --(toby@2022-03-09): 引入其他文件配置 \n\
    --  例如 include config.path filename = config.path \n\
	local function include(filename)\n\
		local last_path = current_path\n\
\n\
        --(toby@2022-03-09): 解析filename 模式为 (path/)(name) \n\
		local path, name = filename:match([[(.*]]..sep..[[)(.*)$]])\n\
		if path then\n\
			if path:sub(1,1) == sep then	-- root\n\
                --(toby@2022-03-09): 路径首字符为 正斜杠 表示绝对路径 \n\
				current_path = path\n\
			else\n\
                --(toby@2022-03-09): 相对路径 \n\
				current_path = current_path .. path\n\
			end\n\
		else\n\
            --(toby@2022-03-09): 就在当前目录，没有匹配出path \n\
			name = filename\n\
		end\n\
\n\
        --(toby@2022-03-09): 打开配置文件 \n\
		local f = assert(io.open(current_path .. name))\n\
\n\
        --(toby@2022-03-09): 读取所有行到code \n\
		local code = assert(f:read [[*a]])\n\
\n\
        --(toby@2022-03-09): 将配置中的 $XXX 转化为环境变量XXX的值 \n\
		code = string.gsub(code, [[%$([%w_%d]+)]], getenv)\n\
		f:close()\n\
\n\
        --(toby@2022-03-09): load (chunk [, chunkname [, mode [, env]]]) \n\
        --  _ENV = result \n\
        --  加载配置内容到 result \n\
		assert(load(code,[[@]]..filename,[[t]],result))()\n\
		current_path = last_path\n\
	end\n\
\n\
	setmetatable(result, { __index = { include = include } })\n\
	local config_name = ...\n\
	include(config_name)\n\
	setmetatable(result, nil)\n\
	return result\n\
";

int
main(int argc, char *argv[]) {
	const char * config_file = NULL ;
	if (argc > 1) {
		config_file = argv[1];
	} else {
		fprintf(stderr, "Need a config file. Please read skynet wiki : https://github.com/cloudwu/skynet/wiki/Config\n"
			"usage: skynet configfilename\n");
		return 1;
	}

    /* toby@2022-03-08): 初始化线程数据 struct skynet_node */
	skynet_globalinit();
    /* toby@2022-03-08): 初始化环境lua虚拟机 struct skynet_env */
	skynet_env_init();

    /* toby@2022-03-08): 屏蔽pipe信号 */
	sigign();

	struct skynet_config config;

#ifdef LUA_CACHELIB
	// init the lock of code cache
	luaL_initcodecache();
#endif

	struct lua_State *L = luaL_newstate();
	luaL_openlibs(L);	// link lua lib

	int err =  luaL_loadbufferx(L, load_config, strlen(load_config), "=[skynet config]", "t");
	assert(err == LUA_OK);
	lua_pushstring(L, config_file);

    /* toby@2022-03-08): 加载配置文件 */
	err = lua_pcall(L, 1, 1, 0);
	if (err) {
		fprintf(stderr,"%s\n",lua_tostring(L,-1));
		lua_close(L);
		return 1;
	}

	_init_env(L); /* toby@2022-03-09): 读取配置到c环境中 */
	lua_close(L); /* toby@2022-03-10): 关闭临时虚拟机 */

	config.thread =  optint("thread",8); /* toby@2022-03-10): 工作线程数 */
	config.module_path = optstring("cpath","./cservice/?.so"); /* toby@2022-03-10): c服务路径 */
	config.harbor = optint("harbor", 1); /* toby@2022-03-10): 集群节点id */
	config.bootstrap = optstring("bootstrap","snlua bootstrap");
	config.daemon = optstring("daemon", NULL); /* toby@2022-03-10): 后台模式，存放进程id的文件名 */
	config.logger = optstring("logger", NULL); /* toby@2022-03-10): 日志的路径名，不配置的话则输出到标准输出，需要开前台模式才能看到 */
	config.logservice = optstring("logservice", "logger");
	config.profile = optboolean("profile", 1);

	skynet_start(&config);
	skynet_globalexit();

	return 0;
}
