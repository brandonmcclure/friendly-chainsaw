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
	Invoke-Pester ./Modules/Tests/

