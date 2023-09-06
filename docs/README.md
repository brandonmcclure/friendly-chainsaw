# friendly-chainsaw

[![Docker Stars](https://img.shields.io/docker/stars/bmcclure89/fc_powershell.svg?style=flat-square)](https://hub.docker.com/r/bmcclure89/fc_powershell/) [![Docker Pulls](https://img.shields.io/docker/pulls/bmcclure89/fc_powershell.svg?style=flat-square)](https://hub.docker.com/r/bmcclure89/fc_powershell/)

A collection of my PowerShell functions and scripts that I have developed over time. There are functions to help with logging and Text to Speech (FC_Log); my git workflow (FC_Git module); setting up/administering windows PCs (FC_SysAdmin); querying/administering SQL server and generally working with data (Excel/Flat files, ssas, ssis, crystal reports etc. inside of FC_Data); as well as other more fun stuff (render a Blender file, wrappers for GBA emulator, etc. in FC_Misc). 

As I primarily use pwsh core nowadays, these modules are designed to be pwsh core compatible.

## Using

### Powershell Gallery

Use [PSGallery](https://www.powershellgallery.com/) to install and update your local modules. I am working towards CI/CD setup for publishing and it still needs some more automation, so there may be some delay in getting the latest versions published, but this is a much better way to install and manage your modules than hacking your `$env:PSModulePath` 

The 2 main modules that you need are:
* [FC_Log](https://www.powershellgallery.com/packages/FC_Log)
* [FC_Core](https://www.powershellgallery.com/packages/FC_Core)

The other modules are independent of each other.
* [FC_Docker](https://www.powershellgallery.com/packages/FC_Docker/1.0.0)
* [FC_Git](https://www.powershellgallery.com/packages/FC_Git)
* [FC_Data](https://www.powershellgallery.com/packages/FC_Data)
* [FC_MicrosoftGraph](https://www.powershellgallery.com/packages/FC_MicrosoftGraph)
* [FC_Misc](https://www.powershellgallery.com/packages/FC_Misc)
* [FC_SysAdmin](https://www.powershellgallery.com/packages/FC_SysAdmin)
* [FC_TFS](https://www.powershellgallery.com/packages/FC_TFS)

### Directly access via source code

Clone the repository locally and add the /Modules/ directory into your `$env:PSModulePath` via your `$PROFILE`. My profile on development machines includes a section like below to use the modules directly from source. If running on Windows, you will need to replace the `:` with `;`

```powershell
if (!($env:PSModulePath -Like "*:/home/brandon/git/friendly-chainsaw/Modules/*")){
        $env:PSModulePath = $env:PSModulePath + ":/home/brandon/git/friendly-chainsaw/Modules/:"
}
```

### Docker

To open an interactive shell:

`docker run -it bmcclure89/fc_powershell:main`

To mount a directory and run a script in an interactive way:

`docker run -v ${PWD}:/work -it bmcclure89/fc_powershell:main pwsh /work/Scripts/Invoke-DockerScriptExample.ps1 "Brandon"`

### Building/Running the tests

Use `make build` and `make test` to build the module files and run the tests. This will run some helper docker images ([src](https://github.com/brandonmcclure/friendly-chainsaw-docker)) to keep the environment consistent.

You can run the tests manually with pester as well! 

## Contributing

This is a collection of scripts that I use daily. As such, I don't really have a goal for this code (other than to make my daily life more automated!). If you have an improvement or an idea, open a pull request with your contribution! 

## License

This project is licensed under the MIT License unless specified otherwise. I see the [LICENSE](LICENSE) file for details
