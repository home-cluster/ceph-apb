REGISTRY         ?= docker.io
ORG              ?= homecluster
TAG              ?= $(shell git rev-parse --short HEAD)
IMAGE            ?= $(REGISTRY)/$(ORG)/ceph-apb:${TAG}
APB_DIR          ?= .
.DEFAULT_GOAL    := build

update: ## Pull new source files from the Rook project
	$(eval tmpdir := $(shell mktemp -d))
	git clone https://github.com/rook/rook.git ${tmpdir}/rook
	for item in scc cluster storageclass ; do \
		cp ${tmpdir}/rook/cluster/examples/kubernetes/ceph/$${item}.yaml files/$${item}.yaml ; \
	done
	cp ${tmpdir}/rook/cluster/examples/kubernetes/ceph/operator.yaml templates/operator.yaml
	sed -i '/ROOK_HOSTPATH_REQUIRES_PRIVILEGED/{n;s/\(.*value: \)"false"/\1"{{ rook_requires_privileged }}"/}' templates/operator.yaml
	sed -i 's/\(.*\)# \(- name: FLEXVOLUME_DIR_PATH\)/\1\2/' templates/operator.yaml
	sed -i '/FLEXVOLUME_DIR_PATH/{n;s|\(.*\)#\(\s*value: \).*|\1\2"{{ flex_volume_plugin_dir }}"|}' templates/operator.yaml
	rm -rf ${tmpdir}

build: ## Build the APB
ifeq ($(TAG),canary)
	docker build -f ${APB_DIR}/Dockerfile  --build-arg APB=${TAG} -t ${IMAGE} ${APB_DIR}
else ifneq (,$(findstring release,$(TAG)))
	docker build -f ${APB_DIR}/Dockerfile  --build-arg APB=${TAG} -t ${IMAGE} ${APB_DIR}
else
	docker build -f ${APB_DIR}/Dockerfile -t ${IMAGE} ${APB_DIR}
endif

publish: build ## Publish the APB
	@echo "Publishing to ${IMAGE}"
ifdef PUBLISH
	docker push ${IMAGE}
else
	@echo "Must set PUBLISH, here be dragons"
endif

help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ''

.PHONY: build deploy help
