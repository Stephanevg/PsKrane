
# PsKrane
![logo](./Images/PsKrane_logo.png)

[![PsKrane](https://img.shields.io/powershellgallery/dt/PsKrane.svg)](https://www.powershellgallery.com/packages/PsKrane/)

PSKrane is an Opiniated cross-platform Powershell scaffold & build module for powershell modules and scripts.

It allows to scaffold, build, and publish your powershell sripts and modules all with just a few standard lines of code.

PsKrane **standardize and simplifies** the steps a powershell developer has to follow for the creation of powershell modules and scripts.

It has been developed to with Continuous integration & Continous deployment (CICD) in mind. Pskrane unifies the experience from the developer's laptop, all the way accross multiple different pipeling (CI/CD) tools.

# Dependencies

PsKrane has has literaly **no dependencies** so you just need one single module : **PsKrane**. That's it!

PsKrane is the single and unique tool you need to scaffold, write, build, test and publish your powershell modules & scripts.

# Standards

PsKrane implements the [community best practises](https://github.com/PoshCode/PowerShellPracticeAndStyle) and gives you a framework that will implement these standards out of the box.

# Aren't there already other existing build / scaffold projects

> There are quite a few other projects existing, indeed! If you are already familiar with them, you can keep using them if you want. PsKrane offers an **alternative**, but it can stil integrate **easily** with other tools.

PsKrane tries to fix a few drawbacks:
- There are A LOT of different options for:
  -   Building powershell modules
  -   Scaffolding powershell modules
-  Too few options for:
   - Building powershell Scripts
   - Scaffolding powershell scripts
     
- Some of these build have **A LOT** of external dependencies and often force you to learn a new build framework or language.
- PsKrane is heavily tested and well documented

The learning curve of PSKrane is **extremly low** and you can get things up and running with one single command ([See Getting started section](#getting-started))
PsKrane **Is** a well documented Powershell module, simple to use, and makes the discoverability really easy. 
If there is a problem in the module, there is **one single location** where to ask for help / report the problem: **This project**.


# Getting Started

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

