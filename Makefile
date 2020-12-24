ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

# Create a user scoped variable for the SA password before running
#  [Environment]::SetEnvironmentVariable("CD_SA_PASSWORD", (ConvertTo-SecureString 'd0ckerSA' -AsPlainText -Force), "User")
#  [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY", "", "Process")


projectName := sqlserver# This should be the folder name this Makefile is in to match what the build script will name it as. IDK how to get the current directory in pure make that works on windows
# https://stackoverflow.com/questions/2004760/get-makefile-directory
registry := localhost:5000/#This can be helpful if testing our infrastructure. If not leave blank to only create a local image

SHELL := pwsh.exe
.SHELLFLAGS := -noprofile -command

all: build

#  Build: should build the project. In the case of docker this should build/tag the images in a consistent method. It has a preq on the setup target. So if you run 'make build' the setup target/script will run as well automatically. 
build: 
	./Modules/Build-ALLFCModules.ps1 -moduleName @('FC_Core.psm1','FC_Docker.psm1')

%:
	./Modules/Build-ALLFCModules.ps1 -moduleName @('$*.psm1')

test: 
	Invoke-Pester ./Modules/Tests/

