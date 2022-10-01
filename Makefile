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

.PHONY: all clean test run lint
all: build docker_build

getcommitid: 
	$(eval COMMITID = $(shell git log -1 --pretty=format:"%H"))
getbranchname:
	$(eval BRANCH_NAME = $(shell (git branch --show-current ) -replace '/','.'))

build: 
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build:main -pathToSearch '/build' -logLevel Info -moduleAuthor Brandon McClure
build_%:
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build:main -pathToSearch '/build' -logLevel Info -moduleName @('$*.psm1') -moduleAuthor "Brandon McClure"

test: 
	docker run --rm -it -w /tests -v $${PWD}:/tests bmcclure89/fc_pwsh_test:main

test_%: 
	docker run --rm -it -w /tests -v $${PWD}:/tests bmcclure89/fc_pwsh_test:main pwsh -c Invoke-Pester -Path '/tests/Modules/**/$*.Tests.ps1' -OutputFile /tests/PesterResults.xml -OutputFormat NUnitXml;

docker_build: getcommitid getbranchname
	docker build --load -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):latest -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(BRANCH_NAME) -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(BRANCH_NAME).$(COMMITID) .

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

lint: lint_mega

lint_mega:
	docker run -v $${PWD}:/tmp/lint oxsecurity/megalinter:v6
lint_goodcheck:
	docker run -t --rm -v $${PWD}:/work sider/goodcheck check
lint_goodcheck_test:
	docker run -t --rm -v $${PWD}:/work sider/goodcheck test
lint_makefile:
	docker run -v $${PWD}:/tmp/lint -e ENABLE_LINTERS=MAKEFILE_CHECKMAKE oxsecurity/megalinter-ci_light:v6.10.0