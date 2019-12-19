# VersionUpdater

This is a simple Swift command line program that reads specified text files and searches for specific lines and updates them as instructed.

## Requirements

In order to work, VersionUpdater needs versioning information. Versioning information is kept in a file in a given project in a specific format. When run VersionUpdator reads the file and does a very simple string search for certain text and then modifies it as needed.

> VersionUpdater requires that the version file be a .swift file.
> VersionUpdater requires that the read me file be in markdown format.

### Versioning information needed

VersionUpdater needs the specific strings below to be present in the version file.

| String  | Symbolic  | Use  |Type|
|:----------|:----------|:----------|:--|
| `public static let BuildTime:`   | `.BuildTime`   | The date/time of the build. Supplied by VersionUpdator.   |`String`|
| `public static let BuildIncrement:`    | `.BuildIncrement`   | Value to use to increment the built count. Supplied by the application. Not modified by VersionUpdator.    |`Integer`|
| `public static let BuildDate:`|`.BuildDate`|The date of the build. Supplied by VersionUpdator.|`String`|
| `public static let Build:`|`.BuildNumber`|The build number. Updated by VersionUpdator.|`Integer`|
| `public static let BuildID:`|`.BuildID`|The ID of the build. Updated by VersionUpdator.|`UUID`|
| `public static let MajorVersion:`|`.MajorVersion`|The major version number. Supplied by the application and not modified by VersionUpdator.|`String` (interpreted as an integer)|
| `public static let MinorVersion:`|`.MinorVersion`|The minor version number. Supplied by the application and not modified by VersionUpdator.|`String` (interpreted as an integer)|
| `public static let VersionTag:`|`.VersionTag`|Tag string for the version. Not used extensively yet.|`String`|

VersionUpdate needs the specific string below to be present in the read me file.

|String|Symbolic|Use|Type|
|:--|:--|:--|:--|
|`Most recent build:`|`.MostRecentBuild`|The text that identifies the line to update with build information.|`String`|

### Supplied functions

The versioning file (usually with the name `Versioning.swift`) supplies several functions to make version retreival easier and more convenient.

|Function|Usage|
|:--|:--|
|`MakeVersionString`|Returns a string with the major and minor version numbers with optional prefix and suffix.|
|`MakeSimpleVersionString`|Returns a simple version string with optional build number.|
|`MakeBuildString`|Returns a string with the build number, date, and time.|
|`AuthorList`|Returns a list of authors, optionally alphabetized by last name.|
|`CopyrightText`|Returns full copyright text.|
|`ProgramIDAsUUID`|Returns the program's ID (assigned by the application, not VersionUpdater) as a UUID type, not the native string type.|
|`MakeVersionParts`|Return various parts of the versioning information as an array of tuples, with item `0` identifying the contents of item `1` for each tuple.
|`MakeVersionBlock`|Returns a multi-line string with versioning information.|
|`MakeAttributedVersionBlockEx`|Returns a multi-line, attributed string (good only for macOS/iOS/iPadOS) with versioning information. Allows for finer grain setting of attributes than `MakeAttributedVersionBlock`.|
|`MakeAttributedVersionBlock`|Returns a multi-line, attributed string (good only for macOS/iOS/iPadOS) with versioning information.|
|`EmitXML`|Emits versioning information as an XML fragment.|

Some properties and fields that are also useful.

|Property|Usage|
|:--|:--|
|`CopyrightYears`|Array property that contains a set of years related to the copyright.|
|`CopyrightHolder`|String property that contains the name of the copyright holder.|
|`IsReleaseBuild`|Set by the caller to indicate whether the build is for release or not. Defaults to `false`.|

The data that must be present in the versioning file (most commonly named `Versioning.swift`) is shown below:

|Field|Use|Type|Required|
|:--|:--|:--|:--|
|`MajorVersion`|The major version number. The user must update this manually.|`String` interpreted as an integer.|Yes|
|`MinorVersion`|The minor version number. The user must update this manually.|`String` interperted as an integer.|Yes|
|`VersionSuffix`|Optional version suffix value. The is supplied by the user.|`String`|No|
|`ApplicationName`|Name of the application to which the versioning information belongs. Supplied by the user.|`String`|No|
|`Tag`|Tag value for the application. Intended to be used for things like "Alpha" or "Beta" but can be anything.|`String`|No|
|`ProgramID`|ID of the program.|`UUID` in string format.|Yes|
|`IntendedOS`|String with the name of OSes the program is intended to run on.|`String`|No|
|`Build`|Current build number. Updated by VersionUpdater. While this is updated by VersionUpdater, the user can set this to any initial (or subsequent) value desired.|`Integer`|Yes|
|`BuildIncrement`|The value to increment the build number with each update. Unless otherwise required, should leave at the default value of `1`.|`Integer`|Yes|
|`BuildID`|ID of the build. Created and supplied by VersionUpdater.|`String` interpreted as a `UUID`.|Yes|
|`BuildDate`|Date of the build. Created and supplied by VersionUpdater.|`String` interpreted as a `Date`|Yes|
|`BuildTime`|Time of the build. Created and supplied by VersionUpdater.|`String` interpreted as a `Date`|Yes|
|`CopyrightYears`|List of years the program is in copyright.|`[String]` with each entry a year. Should be in chronological order.|Yes|
|`CopyrightHolder`|String of the copyright holder(s) names.|`String`|Yes|
|`Authors`|Array of the names of the authors of the program. Names should be in given name, family name order.|`[String]`|Yes|

## Usage

The most efficient way to use VersionUpdater is as a script step in Xcode. To ensure proper timing synchronization (eg, the build date is shown in the most current build), the script step *must* be executed before the compile step.

VersionUpdater takes two command line parameters: 
1) The project's version information file (usually `Versioning.swift`) that must be a `.swift` file.
2) An optional read me file. The version information file must be the first parameter, and if specified, the read me file the second parameter. This must be a markdown file.
