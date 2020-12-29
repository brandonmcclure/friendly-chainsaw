ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

all: build

build: 
	./Modules/Build-ALLFCModules.ps1
%:
	./Modules/Build-ALLFCModules.ps1 -moduleName @('$*.psm1')

test: 
	docker run --rm -it -w /tests -v $${PWD}:/tests bmcclure89/fc_pwsh_tests

