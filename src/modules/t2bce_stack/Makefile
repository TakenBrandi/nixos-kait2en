obj-m += t2bce_dma/
obj-m += t2bce_core/
obj-m += t2bce_vhci/
obj-m += t2bce_audio/

ifneq ($(CONFIG_V4L2_MEM2MEM_DEV),)
obj-m += t2bce_ave/
obj-m += t2bce_sidecar/
endif

KVERSION := $(KERNELRELEASE)
ifeq ($(origin KERNELRELEASE), undefined)
KVERSION := $(shell uname -r)
endif

KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)

.PHONY: all clean

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
