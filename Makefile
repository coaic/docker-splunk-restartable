SHELL := /bin/bash
IMAGE_VERSION ?= "latest"
DOCKER_BUILD_FLAGS = 
SPLUNK_ANSIBLE_BRANCH ?= master
SPLUNK_COMPOSE ?= docker-compose.yml
# Set Splunk version/build parameters here to define downstream URLs and file names
SPLUNK_PRODUCT := splunk
SPLUNK_PASSWORD ?= Passw0rd123
SPLUNK_VERSION := 7.2.0
SPLUNK_BUILD := 8c86330ac18
SPLUNK_ARCH = x86_64

# Linux Splunk arguments
SPLUNK_LINUX_FILENAME ?= splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-${SPLUNK_ARCH}.tgz
SPLUNK_LINUX_BUILD_URL ?= https://download.splunk.com/products/${SPLUNK_PRODUCT}/releases/${SPLUNK_VERSION}/linux/${SPLUNK_LINUX_FILENAME}

.PHONY: tests seed-default

all: splunk

ansible:
	if [ -d "modules/splunk-ansible" ]; then \
		echo "Ansible directory exists - skipping clone"; \
	else \
		git clone https://github.com/coaic/splunk-ansible.git --branch ${SPLUNK_ANSIBLE_BRANCH} modules/splunk-ansible; \
	fi

##### Splunk image #####
splunk: ansible
	docker-compose build \
	  --build-arg SPLUNK_BUILD_URL=${SPLUNK_LINUX_BUILD_URL} \
		--build-arg SPLUNK_FILENAME=${SPLUNK_LINUX_FILENAME} 

##### Run container with compose #####
compose-up: compose-down
	docker-compose -f ./${SPLUNK_COMPOSE} up --detach
	docker-compose -f ./${SPLUNK_COMPOSE} logs --follow

##### Start a previously stopped container
compose-start:
	docker-compose -f ./${SPLUNK_COMPOSE} start
	docker-compose -f ./${SPLUNK_COMPOSE} logs --follow

##### Stop a previously started/upped container
compose-stop:
	docker-compose -f ./${SPLUNK_COMPOSE} stop
	docker-compose -f ./${SPLUNK_COMPOSE} logs --follow

compose-down:
	docker-compose -f ./${SPLUNK_COMPOSE} down --volumes --remove-orphans || true

test: clean ansible

clean:
	docker system prune -f --volumes

seed-default:
	if [ -f ansible-configs/defaults/default.yml ]; then \
		echo "Ansible default.yml exists - skipping seeding"; \
  else \
    docker run --rm -e "SPLUNK_PASSWORD=${SPLUNK_PASSWORD}" splunk/splunk-debian-9:latest create-defaults > ansible-configs/defaults/default.yml; \
  fi    
