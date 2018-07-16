REGISTRY         ?= docker.io
ORG              ?= homecluster
TAG              ?= $(shell git rev-parse --short HEAD)
IMAGE            ?= $(REGISTRY)/$(ORG)/ceph-apb:${TAG}
APB_DIR          ?= .
.DEFAULT_GOAL    := build

update: ## Pull new source files from the Rook project
	$(eval tmpdir := $(shell mktemp -d))
	git clone https://github.com/rook/rook.git ${tmpdir}/rook
	# Static files
	for item in scc dashboard-external ; do \
		cp ${tmpdir}/rook/cluster/examples/kubernetes/ceph/$${item}.yaml files/$${item}.yaml ; \
	done
	# Operator
	echo "Copy operator and setup template options"
	cp ${tmpdir}/rook/cluster/examples/kubernetes/ceph/operator.yaml templates/operator.yaml
	sed -i '/ROOK_HOSTPATH_REQUIRES_PRIVILEGED/{n;s/\(.*value: \)"false"/\1"{{ rook_requires_privileged }}"/}' templates/operator.yaml
	sed -i 's/\(.*\)# \(- name: FLEXVOLUME_DIR_PATH\)/\1\2/' templates/operator.yaml
	sed -i '/FLEXVOLUME_DIR_PATH/{n;s|\(.*\)#\(\s*value: \).*|\1\2"{{ flex_volume_plugin_dir }}"|}' templates/operator.yaml
	# Cluster
	echo "Copy cluster and setup template options"
	cp ${tmpdir}/rook/cluster/examples/kubernetes/ceph/cluster.yaml templates/cluster.yaml
	sed -i 's/\(\s*hostNetwork:\).*/\1 {{ use_host_network }}/' templates/cluster.yaml
	sed -i '/mon:/{n;s/\(\s*count:\).*/\1 {{ mon_count }}/}' templates/cluster.yaml
	sed -i 's/\(\s*allowMultiplePerNode:\).*/\1 {{ allow_multiple_mon_per_node }}/' templates/cluster.yaml
	sed -i '/dashboard:/{n;s/\(\s*enabled:\).*/\1 {{ enable_dashboard }}/}' templates/cluster.yaml
	sed -i 's/\(\s*useAllNodes:\).*/\1 {{ use_all_nodes }}/' templates/cluster.yaml
	sed -i 's/\(\s*useAllDevices:\).*/\1 {{ use_all_devices }}/' templates/cluster.yaml
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
