ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

REGISTRY_NAME := 
REPOSITORY_NAME := bmcclure89/
IMAGE_NAME := fc_powershell
TAG := :latest
PLATFORMS := linux/amd64,linux/arm64,linux/arm/v7

all: build

build: 
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build
%:
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build -logLevel Info -pathToSearch /build -moduleName @('$*.psm1') -moduleAuthor "Brandon McClure"

test: 
	docker run --rm -it -w /tests -v $${PWD}:/tests bmcclure89/fc_pwsh_tests

docker_build:
	docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) .

docker_build_multiarch:
	docker buildx build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) --platform $(PLATFORMS) .

docker_run:
	docker run -it $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

docker_package:
	$$PackageFileName = "$$("$(IMAGE_NAME)" -replace "/","_").tar"; docker save $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -o $$PackageFileName

docker_size:
	docker inspect -f "{{ .Size }}" $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	docker history $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

docker_publish:
	docker login; docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG); docker logout
