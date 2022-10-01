# friendly-chainsaw
A collection of PowerShell scripts that I use a lot. There are functions to help with my git workflow (FC_Git module), setting up/administering windows PCs (FC_SysAdmin), querying/administering SQL server and generally working with data (Excel/Flat files, ssas, ssis, crystal reports etc. inside of FC_Data), as well as other more fun stuff (render a Blender file, wrappers for GBA emulator, etc. in FC_Misc). I comment in the code when I have gotten inspiration (or just plain copied the code) from others. 

I am attempting to convert these to pwsh core compatible. Most are already, although ymmv. 

All the modules and scripts use my logging framework and a few other core functions from FC_Log and FC_Core. You are welcome to use the code/modules themselves or copy paste bits that suite you. 

[![Docker Stars](https://img.shields.io/docker/stars/bmcclure89/fc_powershell.svg?style=flat-square)](https://hub.docker.com/r/bmcclure89/fc_powershell/) [![Docker Pulls](https://img.shields.io/docker/pulls/bmcclure89/fc_powershell.svg?style=flat-square)](https://hub.docker.com/r/bmcclure89/fc_powershell/)

# Getting Started
## Slower/Better/Less up to date

Use [PSGallery](https://www.powershellgallery.com/) to install and update your local modules. I am working towards CI/CD setup for publishing and it still needs some more automation, so there may be some delay in getting the latest versions published, but this is a much better way to install and manage your modules than hacking your `$env:PSModulePath` 

The 2 main modules that you need are:
* [FC_Log](https://www.powershellgallery.com/packages/FC_Log)
* [FC_Core](https://www.powershellgallery.com/packages/FC_Core)

The other modules are independant of each other.
* [FC_Docker](https://www.powershellgallery.com/packages/FC_Docker/1.0.0)
* [FC_Git](https://www.powershellgallery.com/packages/FC_Git)
* [FC_Data](https://www.powershellgallery.com/packages/FC_Data)
* [FC_MicrosoftGraph](https://www.powershellgallery.com/packages/FC_MicrosoftGraph)
* [FC_Misc](https://www.powershellgallery.com/packages/FC_Misc)
* [FC_SysAdmin](https://www.powershellgallery.com/packages/FC_SysAdmin)
* [FC_TFS](https://www.powershellgallery.com/packages/FC_TFS)

## Quickest/most up to date

Clone the repository locally and add the /Modules/ directory into your `$env:PSModulePath`

## Building/Running the tests

Use `make build` and `make test` to automate. 

This will run some helper docker images ([src](https://github.com/brandonmcclure/friendly-chainsaw-docker))

You can run the tests manually with pester as well

## Contributing

This is a collection of scripts that I use daily. As such, I don't really have a goal for this code (other than to make my daily life more automated!). If you have an improvement or an idea, open a pull request with your contribution or send me a message! I am open to contributions to this code base, as I have found this code very useful and have been enjoying the learning process of writing reusable PowerShell code.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
