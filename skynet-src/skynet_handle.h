#ifndef SKYNET_CONTEXT_HANDLE_H
#define SKYNET_CONTEXT_HANDLE_H

#include <stdint.h>

// reserve high 8 bits for remote id
#define HANDLE_MASK 0xffffff
#define HANDLE_REMOTE_SHIFT 24

struct skynet_context;

/* toby@2022-03-02): 注册服务到句柄管理器 返回服务id */
/* toby@2022-03-02): 高8位用作集群节点标识 低24位存储本进程内的服务id */
uint32_t skynet_handle_register(struct skynet_context *);
/* toby@2022-03-02): 回收句柄 销毁服务 */
int skynet_handle_retire(uint32_t handle);
/* toby@2022-03-02): 回收所有句柄 */
void skynet_handle_retireall();

/* toby@2022-03-03): 通过句柄管理器获取服务 */
struct skynet_context * skynet_handle_grab(uint32_t handle);

/* toby@2022-03-03): 根据名字字符串大小二分查找服务id */
uint32_t skynet_handle_findname(const char * name);
/* toby@2022-03-03): 插入新服务名字 按字符串大小排序 */
const char * skynet_handle_namehandle(uint32_t handle, const char *name);

/* toby@2022-03-03): 初始化句柄管理器 static struct handle_storage *H */
void skynet_handle_init(int harbor);

#endif
