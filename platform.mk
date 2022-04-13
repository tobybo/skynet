PLAT ?= none
PLATS = linux freebsd macosx

CC ?= gcc

#声明伪目标
.PHONY : none $(PLATS) clean all cleanall

#ifneq ($(PLAT), none)

.PHONY : default

default :
	$(MAKE) $(PLAT)

#endif

none :
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

# 静态库
SKYNET_LIBS := -lpthread -lm

# -shared: 使源码编译成动态库 .so 文件
# -fPIC: 生成位置无关代码，从而可以在任意地方调用生成的动态库
SHARED := -fPIC --shared

# -E 仅预处理
# -Wl,option 将 option 传递给 link 程序
EXPORT := -Wl,-E -Wl,-rpath=3rd/http-parser/lib

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
macosx : EXPORT :=

# 链接动态库需要用到的库 包含 dlopen 等接口
macosx linux : SKYNET_LIBS += -ldl
# 链接实时库 包含 shm_open 等接口
linux freebsd : SKYNET_LIBS += -lrt

# Turn off jemalloc and malloc hook on macosx

macosx : MALLOC_STATICLIB :=
macosx : SKYNET_DEFINES :=-DNOUSE_JEMALLOC

linux macosx freebsd :
	$(MAKE) all PLAT=$@ SKYNET_LIBS="$(SKYNET_LIBS)" SHARED="$(SHARED)" EXPORT="$(EXPORT)" MALLOC_STATICLIB="$(MALLOC_STATICLIB)" SKYNET_DEFINES="$(SKYNET_DEFINES)"
