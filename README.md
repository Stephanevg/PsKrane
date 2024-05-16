# PsKrane
![logo](./Images/PsKrane_logo.png)

[![PSHTML](https://img.shields.io/powershellgallery/dt/PsKrane.svg)](https://www.powershellgallery.com/packages/PsKrane/)

PSKrane is an Opiniated Powershell build module.

It allows to scaffold, build, and publish your powershell sripts and modules all with just a few lines of code.
It has been developed to with Continuous integration & Continous deployment (CICD) in mind. PsKrane is the single tool you will need when you need to build, test and publish your powershell modules / scripts.

The module has literaly **no dependencies** so you just need one single module : **PsKrane**. That's it!

# What about the other existing projects

> There are a few other existing build modules out there, why should I not use one of them? 

If you are already familiar with them, you can keep using them. There are some really good existing options out there. 
PsKrane tries to fix two main drawbacks:
- Some of them are using Scripts, not a powershell module.
- Some of these build modules have **A LOT** of external dependencies.

PsKrane **Is** a Powershell module, simple to use, and makes the discoverability really easy. 
If there is a problem in the module, there is **one single location** where to ask for help, and to report the problem: **This project**.


# Why yet another build module. 

Simply because I have been using these scripts since a VERY long time. So decided clean it up and to open source it.

# Examples 

Git Integration

```powershell
PS> $KraneProject = get-KraneProject
[261,44ms] C:\Users\Stephane\Code\Plop
PS> $KraneProject

ModuleName       : Plop
ModuleFile       : C:\Users\Stephane\Code\Plop\Outputs\Module\Plop.psm1
ModuleDataFile   : C:\Users\Stephane\Code\Plop\Outputs\Module\Plop.psd1
Build            : C:\Users\Stephane\Code\Plop\Build
Sources          : C:\Users\Stephane\Code\Plop\Sources
Tests            : C:\Users\Stephane\Code\Plop\Tests
Outputs          : C:\Users\Stephane\Code\Plop\Outputs
Tags             : {PSEdition_Core, PSEdition_Desktop}
Description      : This module is a test module
ProjectUri       : http://link.com/
IsGitInitialized : False
KraneFile        : ProjectName:Plop ProjectType:Module
ProjectType      : Module
Root             : C:\Users\Stephane\Code\Plop
ProjectVersion   : 0.2.2

[50,27ms] C:\Users\Stephane\Code\Plop
PS> git init
Initialized empty Git repository in C:/Users/Stephane/Code/Plop/.git/
[202,92ms] C:\Users\Stephane\Code\Plop [HEAD]
PS> $KraneProject = get-KraneProject
[16,27ms] C:\Users\Stephane\Code\Plop [HEAD]
PS> $KraneProject

ModuleName       : Plop
ModuleFile       : C:\Users\Stephane\Code\Plop\Outputs\Module\Plop.psm1
ModuleDataFile   : C:\Users\Stephane\Code\Plop\Outputs\Module\Plop.psd1
Build            : C:\Users\Stephane\Code\Plop\Build
Sources          : C:\Users\Stephane\Code\Plop\Sources
Tests            : C:\Users\Stephane\Code\Plop\Tests
Outputs          : C:\Users\Stephane\Code\Plop\Outputs
Tags             : {PSEdition_Core, PSEdition_Desktop}
Description      : This module is a test module
ProjectUri       : http://link.com/
IsGitInitialized : True
KraneFile        : ProjectName:Plop ProjectType:Module
ProjectType      : Module
Root             : C:\Users\Stephane\Code\Plop
ProjectVersion   : 0.2.2

```

