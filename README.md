
# PsKrane
![logo](./Images/PsKrane_logo.png)

[![PsKrane](https://img.shields.io/powershellgallery/dt/PsKrane.svg)](https://www.powershellgallery.com/packages/PsKrane/)

PSKrane is an Opiniated cross-platform Powershell scaffold & build module for powershell modules and scripts.

It allows to scaffold, build, and publish your powershell sripts and modules all with just a few standard lines of code.

PsKrane **standardize and simplifies** the steps a powershell developer has to follow for the creation of powershell modules and scripts.

It has been developed with Continuous integration & Continous deployment (CICD) in mind. Pskrane unifies the experience from the developer's laptop, all the way accross multiple different pipeling (CI/CD) tools.

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

# Using Templates

PsKrane allows to generate functions & classes in a standard super easy to 

Since version 0.6.1 it is possible to use the cmdlet `New-KraneItem` in order to add a new function or a class for your project.

This function / class will be created based on a pre-existing template.

Since there are a lot of different use cases and that everybody has their own style and coding principles, there are different ways to consume a __krane template__. 
They work in a hierarchal way, but you can also specifiy a specific template that you would like.

This difference between the templates are called: __Template Types__ and can be defined in 3 different level types.

## Template types:

### Module Templates

PsKrane it's self comes with an existing / default function and class template. These __module templates__  are purpusefully very generic to fit *everybody's* programming needs. These templates are called __module templates__.

It is possible to get more granular and to define your own templates with the two next type of templates.



## System Templates

System templates are system wide templates for functions and classes. These Templates can be used in any __krane__ project.

## Project Templates

Project Templates are templates that are specific to a krane project, can only be found and used in that specific krane project. 

> Ultimatley, it is just a file in a specific folder structure, so you Can actually copy one project template to another project.




