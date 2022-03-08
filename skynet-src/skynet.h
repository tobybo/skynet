#ifndef SKYNET_H
#define SKYNET_H

#include "skynet_malloc.h"

#include <stddef.h>
#include <stdint.h>

#define PTYPE_TEXT 0
#define PTYPE_RESPONSE 1
#define PTYPE_MULTICAST 2
#define PTYPE_CLIENT 3
#define PTYPE_SYSTEM 4
#define PTYPE_HARBOR 5
#define PTYPE_SOCKET 6
// read lualib/skynet.lua examples/simplemonitor.lua
#define PTYPE_ERROR 7
// read lualib/skynet.lua lualib/mqueue.lua lualib/snax.lua
#define PTYPE_RESERVED_QUEUE 8
#define PTYPE_RESERVED_DEBUG 9
#define PTYPE_RESERVED_LUA 10
#define PTYPE_RESERVED_SNAX 11

#define PTYPE_TAG_DONTCOPY 0x10000
#define PTYPE_TAG_ALLOCSESSION 0x20000

struct skynet_context;

void skynet_error(struct skynet_context * context, const char *msg, ...);

/* toby@2022-03-07): 服务的消息处理函数 */
typedef int (*skynet_cb)(struct skynet_context * context, void *ud, int type, int session, uint32_t source , const void * msg, size_t sz);

/* toby@2022-03-07): 服务控制命令处理函数 */
const char * skynet_command(struct skynet_context * context, const char * cmd , const char * parm);

/* toby@2022-03-07): 根据名字查找服务id */
uint32_t skynet_queryname(struct skynet_context * context, const char * name);

/* toby@2022-03-07): 发消息 目的服务用id */
int skynet_send(struct skynet_context * context, uint32_t source, uint32_t destination , int type, int session, void * msg, size_t sz);

/* toby@2022-03-07): 发消息 目的服务用name */
int skynet_sendname(struct skynet_context * context, uint32_t source, const char * destination , int type, int session, void * msg, size_t sz);

/* toby@2022-03-07): 没有调用过 */
int skynet_isremote(struct skynet_context *, uint32_t handle, int * harbor);

/* toby@2022-03-07): 注册消息处理函数 */
void skynet_callback(struct skynet_context * context, void *ud, skynet_cb cb);

uint32_t skynet_current_handle(void);

uint64_t skynet_now(void);

void skynet_debug_memory(const char *info);	// for debug use, output current service memory to stderr

#endif
