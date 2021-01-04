ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

all: build

build: 
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build
%:
	docker run --rm -it -w /build -v $${PWD}:/build bmcclure89/fc_pwsh_build -moduleName @('$*.psm1') -Verbose

test: 
	docker run --rm -it -w /tests -v $${PWD}:/tests bmcclure89/fc_pwsh_tests

