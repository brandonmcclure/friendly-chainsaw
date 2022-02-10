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

all: build docker_build

getcommitid: 
	$(eval COMMITID = $(shell git log -1 --pretty=format:"%H"))

build: 
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build:2d312d66d8dbd7ecf57eac8d8391986092f90cfc -pathToSearch '/build' -logLevel Info -moduleAuthor Brandon McClure
build_%:
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build:2d312d66d8dbd7ecf57eac8d8391986092f90cfc -pathToSearch '/build' -logLevel Info -moduleName @('$*.psm1') -moduleAuthor "Brandon McClure"

test: 
	docker run --rm -it -w /tests -v $${PWD}:/tests bmcclure89/fc_pwsh_test:f9ca37b8dbb9665bdc525a2bddec0da0ad2720f9

docker_build: getcommitid
	docker build --load -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(COMMITID) .

docker_build_multiarch:
	docker buildx build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) --platform $(PLATFORMS) .
	
run: docker_run
docker_run:
	docker run -it $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

docker_package:
	$$PackageFileName = "$$("$(IMAGE_NAME)" -replace "/","_").tar"; docker save $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -o $$PackageFileName

docker_size:
	docker inspect -f "{{ .Size }}" $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	docker history $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

docker_publish:
	docker login; docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG); docker logout

clean:
	Get-ChildItem -Recurse -PAth . -File | where {$$_.Extension -eq '.nuspec'} |Remove-Item -Force

new_module_%:
	@./New-MyModule.ps1 -ModuleName $*