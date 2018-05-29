# friendly-chainsaw
A collection of PowerShell scripts that I use a lot. There are functions to help with my git workflow (FC_Git module), setting up/administering windows PCs (FC_SysAdmin), quering/administering SQL server and generally working with data (Excel/Flat files, ssas, ssis, crystal reports etc inside of FC_Data), as well as other more fun stuff (render a Blender file, wrappers for GBA emulator, etc in  FC_Misc)

All the modules and scripts use my logging framework and a few other core functions from FC_Log and FC_Core. 

# Getting Started
## Slower/Better/Less up to date

Use [PSGallery](https://www.powershellgallery.com/) to install and update your local modules. I am working towards CI setup for publishing so there may be some delay in getting the latest versions published, but this is a much better way to install and manage your modules than hacking your `$env:PSModulePath` 

The 2 main modules that you need are:
* [FC_Log](https://www.powershellgallery.com/packages/FC_Log)
* [FC_Core](https://www.powershellgallery.com/packages/FC_Core)

The other modules are independant of each other.
* [FC_Git](https://www.powershellgallery.com/packages/FC_Git)
* [FC_Data](https://www.powershellgallery.com/packages/FC_Data)
* [FC_MicrosoftGraph](https://www.powershellgallery.com/packages/FC_MicrosoftGraph)
* [FC_Misc](https://www.powershellgallery.com/packages/FC_Misc)
* [FC_SysAdmin](https://www.powershellgallery.com/packages/FC_SysAdmin)
* [FC_TFS](https://www.powershellgallery.com/packages/FC_TFS)

## Quickest/most up to date

Clone the repository localy and add the /Modules/ directory into your `$env:PSModulePath`

## Running the tests

TODO: Create some pester tests!

## Contributing

Open a pull request with your contribution! I am open to contributions to this code base, as I have found this code very useful and have been enjoying the learning proccess of writing reusable powershell code.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
