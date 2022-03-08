#ifndef SKYNET_MESSAGE_QUEUE_H
#define SKYNET_MESSAGE_QUEUE_H

#include <stdlib.h>
#include <stdint.h>

struct skynet_message {
	uint32_t source; /* toby@2022-03-02): 发送方服务id */
	int session;     /* toby@2022-03-02): 标识消息，类似消息序号，逻辑层用到 */
	void * data;
	size_t sz;       /* toby@2022-03-02): 64位操作系统下8个字节 */
};

// type is encoding in skynet_message.sz high 8bit
#define MESSAGE_TYPE_MASK (SIZE_MAX >> 8)
#define MESSAGE_TYPE_SHIFT ((sizeof(size_t)-1) * 8)

struct message_queue;

void skynet_globalmq_push(struct message_queue * queue);
struct message_queue * skynet_globalmq_pop(void);

struct message_queue * skynet_mq_create(uint32_t handle);

/* toby@2022-03-02): 销毁队列时，剩余消息的处理函数 */
typedef void (*message_drop)(struct skynet_message *, void *);

/* toby@2022-03-02): 标记为待释放，插入全局消息队列 */
void skynet_mq_mark_release(struct message_queue *q);
/* toby@2022-03-02): 如果标记为待释放则销毁消息队列，否则插入全局消息队列 */
void skynet_mq_release(struct message_queue *q, message_drop drop_func, void *ud);

uint32_t skynet_mq_handle(struct message_queue *);

// 0 for success
int skynet_mq_pop(struct message_queue *q, struct skynet_message *message);
void skynet_mq_push(struct message_queue *q, struct skynet_message *message);

// return the length of message queue, for debug
int skynet_mq_length(struct message_queue *q);
int skynet_mq_overload(struct message_queue *q);

/* toby@2022-03-02): 初始化全局消息队列 */
void skynet_mq_init();

#endif
