
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

## Your first project

### Create a powerhell module

To create a powershell module with `PsKrane` You can use one single command to get you there:

```powershell
 New-KraneProject -Type Module -Name "MyFirstModule" -Path C:\Code
```

The particularity of PsKrane is that it comes with a `KraneObject` which is used as the base of every work for almost everything.

When you create a new KraneProject (In this case, a `module` project) the KraneProject object will be returned back to you.


```powershell
S C:\Users\Stephane> New-KraneProject -Type Module -Name "MyFirstModule" -Path C:\Code


ModuleName       : MyFirstModule
Tags             : {PSEdition_Core, PSEdition_Desktop}
Description      :
ProjectUri       :
IsGitInitialized : False
PsModule         : PsModule
TestData         :
Root             : C:\Code\MyFirstModule
KraneFile        : ProjectName:MyFirstModule ProjectType:Module
ProjectType      : Module
ProjectVersion   : 0.0.1
TemplatesPath    :
Templates        : KraneTemplateCollection
```

It has all the important information relative to your PowerShell Project (In this example, it is a Kraneproject of type PowerShell module) and `PsKrane` know's how to work with it.

A `KraneProject` can very easily be retrieved using 

```powershell
PS C:\Users\Stephane> Get-KraneProject -Root C:\Code\MyFirstModule\


ModuleName       : MyFirstModule
Tags             : {PSEdition_Core, PSEdition_Desktop}
Description      :
ProjectUri       :
IsGitInitialized : False
PsModule         : PsModule
TestData         :
Root             : C:\Code\MyFirstModule
KraneFile        : ProjectName:MyFirstModule ProjectType:Module
ProjectType      : Module
ProjectVersion   : 0.0.1
TemplatesPath    :
Templates        : KraneTemplateCollection
```



## Examples

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

PsKrane implements opinonated structures and conventions based on community best practices and shared experiences.

PasKrane has built-in tooling to create a full new official KraneProject using `New-KraneProject`.

To be able to onboard an existing project, the following conditions need to be respected. 
- A specific folder structure must be present.
- a .PsKrane.json needs to be present at the root of the Krane project folder.

__Both of the above conditions can be handled by PsKrane's internal tooling - So that the developper has nothing to worry about.__


# A few words on the folder structure

## Build

The build folder contains everything that is needed for your build process. By default, it contains a script called "Build.Krane.ps1".

## Outputs

Contains the outputed artifacts that are produced by the Build script.
The artifacts are:
- .nuget file
- .psm1 + .psd1 file

## Sources

The sources folder contains the script and class files that compose the powershell module.

## Tests

Contains the pester tests that are used to test the script.

## .krane.json

Is the core file that will mark this folder as a krane supported repository.


# Using Templates

PsKrane allows to generate functions & classes in a standard super easy to 

Since version 0.6.1 it is possible to use the cmdlet `New-KraneItem` in order to add a new function or a class for your project.

This function / class will be created based on a pre-existing template.

Since there are a lot of different use cases and that everybody has their own style and coding principles, there are different ways to consume a __krane template__ through **template locations**.


## Template Locations:

``Template locations`` work in a hierarchal way, respecting the following order:
-> Module
  -> System
    -> Project

Each of the element above is called a **template location** and templates can be defined in each level of the location. The hierarchy will allow to propagate a template, and have it be `overwritten` by the template on the layer below __if__ there is a template that has `the same name` as the one from the level below.

### Module Templates

PsKrane it's self comes with an existing / default function and class templates. These __module templates__  are purpusefully very generic to fit *everybody's* programming needs. These templates are called __module templates__.

It is possible to get more granular and to define your own templates with the two next type of templates.

You can list all the available templates using:

```powershell

Get-KraneTemplate

```
It is also possible to fetch an specific one by 

## System Templates

System templates are system wide templates for functions and classes. These Templates can be used in any __krane__ project.

## Project Templates

Project Templates are templates that are specific to a krane project, can only be found and used in that specific krane project. 

> Ultimatley, it is just a file in a specific folder structure, so you Can actually copy one project template to another project directly if you need. (You must reimport the module and the KraneProject for the most recent changes to be picked up).




