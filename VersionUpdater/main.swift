//
//  main.swift
//  VersionUpdater
//
//  Created by Stuart Rankin on 2/24/18.
//  Copyright © 2018, 2019 Stuart Rankin. All rights reserved.
//

/// This program reads a Swift file with specific versioning information (see `GetLinePrefix` for exact strings searched for)
/// then updates values as required. The program keeps some of the information and if a read me file is specified, it is used
/// to update that file as well. If a read me file is specified but no versioning file, this program will fail with an error
/// because necessary versioning information is not available in such a case.
///
/// The exact name of the files are:
///   - `VersionFileName` contains the name of the Swift source code with the versioning information.
///   - `ReadmeFileName` contains the name of the mark down read me file.

import Foundation

/// Lines we care about in the versioning file.
enum SpecificLines
{
    /// Line that contains the build number.
    case BuildNumber
    /// Line that contains how to increment the build number.
    case BuildIncrement
    /// Line that contains the build date.
    case BuildDate
    /// Line that contains the build time.
    case BuildTime
    /// Line that contains the build ID.
    case BuildID
    /// Line that contains the major version number.
    case MajorVersion
    /// Line that contains the minor version number.
    case MinorVersion
    /// Line that contains the version tag.
    case VersionTag
    /// Line that contains the text to update in the read me file.
    case MostRecentBuild
}

/// English spellings of the months of the year.
let Months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

/// Returns the line prefix for specific lines that contain information we need/modify.
/// - Parameter Specific: The type of line string to return.
func GetLinePrefix(Specific: SpecificLines) -> String
{
    switch Specific
    {
        case .BuildTime:
            return "public static let BuildTime:"
        
        case .BuildIncrement:
            return "private static let BuildIncrement"
        
        case .BuildDate:
            return "public static let BuildDate:"
        
        case .BuildNumber:
            return "public static let Build:"
        
        case .BuildID:
            return "public static let BuildID:"
        
        case .MajorVersion:
            return "public static let MajorVersion:"
        
        case .MinorVersion:
            return "public static let MinorVersion:"
        
        case .VersionTag:
            return "public static let Tag:"
        
        case .MostRecentBuild:
            return "Most recent build:"
    }
}

/// Returns the line index for the specified line.
/// - Parameter Lines: List of lines in which we search for a specific line type.
/// - Parameter WhichLine: The line we are looking for.
/// - Returns: Index of the specified line if found, nil if not found.
func GetLineIndex(_ Lines: [String], WhichLine: SpecificLines) -> Int?
{
    if Lines.count < 1
    {
        return nil
    }
    var Index = 0
    let SubStringSearch = GetLinePrefix(Specific: WhichLine)
    for Line in Lines
    {
        if Line.contains(SubStringSearch)
        {
            return Index
        }
        Index = Index + 1
    }
    return nil
}

/// Convert the part of the passed string on the right of the equality sign into an Int.
/// - Parameter Line: The line to convert.
/// - Returns: The integer value of the right side of the string. Nil on parse error.
func GetIntValue(_ Line: String) -> Int?
{
    let Parts = Line.split(separator: "=")
    if Parts.count != 2
    {
        return nil
    }
    let Part1 = String(Parts[1])
    let SValue = Part1.trimmingCharacters(in: .whitespacesAndNewlines)
    let Value: Int = Int(SValue)!
    return Value
}

/// Returns the right-side of the line (on the right side of the equality symbol) as a string. Quotations
/// marks are removed.
/// - Parameter Line: The line to return the constant string portion.
/// - Returns: The string on the right side, nil on parse error.
func GetStringValue(_ Line: String) -> String?
{
    let Parts = Line.split(separator: "=")
    if Parts.count != 2
    {
        return nil
    }
    let Part1 = String(Parts[1])
    var SValue = Part1.trimmingCharacters(in: .whitespacesAndNewlines)
    SValue = SValue.replacingOccurrences(of: Quote, with: "")
    return SValue
}

/// Quotation character.
let Quote = "\""
/// Current time.
let Now = Date()
/// Calendar used for time-zone specific dates and times.
let Cal = Calendar.current
/// Command line arguments used to gather information and write versioning data.
let Arguments = CommandLine.arguments

/// Default version file name.
var VersionFileName = "Versioning.swift"
/// Default read me file name.
var ReadmeFileName = "README.md"
/// Found the versioning file flag.
var FoundVersioning = false
/// Found the read me file file.
var FoundReadme = false
/// URL of the version file.
var VersionFileURL: URL? = nil
/// URL of the read me file.
var ReadmeFileURL: URL? = nil

/// Read the command line arguments and look for the specific read me and versioning files.
/// Main entry point for the program.
for arg in CommandLine.arguments
{
    let SomeURL = URL(fileURLWithPath: arg)
    let Name = SomeURL.lastPathComponent
    if Name.contains(VersionFileName)
    {
        VersionFileURL = SomeURL
        FoundVersioning = true
        if !FileManager.default.fileExists(atPath: VersionFileURL!.path)
        {
            print("Cannot find \(VersionFileURL!).")
            exit(EXIT_FAILURE)
        }
    }
    if Name.contains(ReadmeFileName)
    {
        ReadmeFileURL = SomeURL
        FoundReadme = true
        if !FileManager.default.fileExists(atPath: ReadmeFileURL!.path)
        {
            print("Cannot find \(ReadmeFileURL!).")
            exit(EXIT_FAILURE)
        }
    }
}

/// The major version number from the version file.
var VersionMajor = ""
/// The minor version number from the version file.
var VersionMinor = ""
/// The version tag from the version file.
var VersionTag = ""
/// The build date from the version file.
var Built = ""
/// The build time from the version file.
var BuiltTime = ""
/// Build sequence from the version file (also known as build number).
var BuildSequence = ""

//If versioning information was found, continue with processing.
if FoundVersioning
{
    //Read the versioning information.
    var Lines: [String]!
    var blob: String = ""
    print("Attempting to read \(VersionFileURL!.path)")
    do
    {
        blob = try String(contentsOfFile: VersionFileURL!.path, encoding: .utf8)
    }
    catch
    {
        print(error)
        exit(EXIT_FAILURE)
    }
    Lines = blob.components(separatedBy: .newlines)
    print("Read \(Lines.count) lines in \((VersionFileURL)!)")
    var Scratch: [String] = [String]()
    for Line in Lines
    {
        Scratch.append(Line.replacingOccurrences(of: "\r\n", with: ""))
    }
    Lines?.removeAll()
    Lines = Scratch
    
    //Get version information for use if we are also updating a read me file.
    if let IdxMajor = GetLineIndex(Lines, WhichLine: .MajorVersion)
    {
        let Raw = Lines[IdxMajor]
        if let Found = GetStringValue(Raw)
        {
            VersionMajor = Found
        }
    }
    if let IdxMinor = GetLineIndex(Lines, WhichLine: .MinorVersion)
    {
        let Raw = Lines[IdxMinor]
        if let Found = GetStringValue(Raw)
        {
            VersionMinor = Found
        }
    }
    if let IdxTag = GetLineIndex(Lines, WhichLine: .VersionTag)
    {
        let Raw = Lines[IdxTag]
        if let Found = GetStringValue(Raw)
        {
            VersionTag = Found
        }
    }
    
    //Get the build increment value.
    let BuildIncrementLine = GetLineIndex(Lines, WhichLine: .BuildIncrement)
    if BuildIncrementLine == nil
    {
        print("Could not find build increment.")
        exit(EXIT_FAILURE)
    }
    let IncrementValue = GetIntValue(Lines[BuildIncrementLine!])
    
    //Get the old build number.
    let BuildNumberLine = GetLineIndex(Lines, WhichLine: .BuildNumber)
    if BuildNumberLine == nil
    {
        print("Could not find build number.")
        exit(EXIT_FAILURE)
    }
    let OldBuildNumber = GetIntValue(Lines[BuildNumberLine!])
    let NewBuildNumber = OldBuildNumber! + IncrementValue!
    let NewBuildLine = "    public static let Build: Int = " + String(describing: NewBuildNumber)
    Lines[BuildNumberLine!] = NewBuildLine
    BuildSequence = "\(NewBuildNumber)"
    
    //Get the build date.
    let BuildDateLine = GetLineIndex(Lines, WhichLine: .BuildDate)
    if BuildDateLine == nil
    {
        print("Could not find build date line number.")
        exit(EXIT_FAILURE)
    }
    let Day = Cal.component(.day, from: Now)
    let Month = Cal.component(.month, from: Now)
    let Year = Cal.component(.year, from: Now)
    let NewDate = String(describing: Day) + " " + Months[Month - 1] + " " + String(describing: Year)
    Built = NewDate
    var NewDateLine = "    public static let BuildDate: String = " + Quote
    NewDateLine = NewDateLine + NewDate + Quote
    Lines[BuildDateLine!] = NewDateLine
    
    //Get the build time.
    let BuildTimeLine = GetLineIndex(Lines, WhichLine: .BuildTime)
    if BuildTimeLine == nil
    {
        print("Could not find build time line number.")
        exit(EXIT_FAILURE)
    }
    let Hour = Cal.component(.hour, from: Now)
    let Minute = Cal.component(.minute, from: Now)
    var SHour = String(describing: Hour)
    if Hour < 10
    {
        SHour = "0" + SHour
    }
    var SMinute = String(describing: Minute)
    if Minute < 10
    {
        SMinute = "0" + SMinute
    }
    var NewTimeLine = "    public static let BuildTime: String = " + Quote
    NewTimeLine = NewTimeLine + SHour + ":" + SMinute + Quote
    Lines[BuildTimeLine!] = NewTimeLine
    BuiltTime = SHour + ":" + SMinute
    
    //Get the build ID.
    let BuildIDLine = GetLineIndex(Lines, WhichLine: .BuildID)
    if BuildIDLine == nil
    {
        print("Could not find build ID line number.")
        exit(EXIT_FAILURE)
    }
    var NewBuildID = "    public static let BuildID: String = " + Quote
    NewBuildID = NewBuildID + UUID().uuidString + Quote
    Lines[BuildIDLine!] = NewBuildID
    
    //Create a new file from the modified data.
    var FinalContents: String = ""
    var Index = 0
    for Line in Lines
    {
        var WriteMe = Line
        if Index < Lines.count - 1
        {
            let Ending = String(WriteMe.suffix(1))
            if Ending != "\n"
            {
                WriteMe = WriteMe + "\n"
            }
        }
        FinalContents = FinalContents + WriteMe
        Index = Index + 1
    }
    
    //Save the updated version file.
    print("Writing results to \((VersionFileURL)!)")
    let Contents: NSString = FinalContents as NSString
    do
    {
        try Contents.write(toFile: VersionFileURL!.path, atomically: true, encoding: String.Encoding.utf8.rawValue)
    }
    catch
    {
        print(error)
    }
}
else
{
    print("No Versioning file found.")
}

//If a read me file was found, update specific lines.
if FoundReadme
{
    if !FoundVersioning
    {
        print("Unable to update \((ReadmeFileURL)!) due to lack of versioning information.")
        exit(EXIT_FAILURE)
    }
    
    //Read the read me file.
    var Lines: [String]!
    print("Attempting to read \(ReadmeFileURL!.path)")
    do
    {
        let blob = try String(contentsOfFile: ReadmeFileURL!.path, encoding: .utf8)
        Lines = blob.components(separatedBy: .newlines)
        print("Read \(Lines.count) lines in \((ReadmeFileURL)!)")
    }
    catch
    {
        print(error)
        exit(EXIT_FAILURE)
    }
    
    var Scratch: [String] = [String]()
    //Remove unnecessary CRLFs.
    for Line in Lines
    {
        Scratch.append(Line.replacingOccurrences(of: "\r\n", with: ""))
    }
    Lines?.removeAll()
    Lines = Scratch
    
    //Search for the proper line to modify, then modify it.
    if let MostRecentIndex = GetLineIndex(Lines, WhichLine: .MostRecentBuild)
    {
        var NewLine = "Most recent build: "
        NewLine.append("**")
        NewLine.append("Version \(VersionMajor).\(VersionMinor)")
        if !VersionTag.isEmpty
        {
            NewLine.append(" \(VersionTag)")
        }
        NewLine.append(", Build \(BuildSequence)")
        NewLine.append(", Build date: \(Built), \(BuiltTime)")
        NewLine.append("**")
        Lines[MostRecentIndex] = NewLine
        
        var FinalContents: String = ""
        var Index = 0
        for Line in Lines
        {
            var WriteMe = Line
            if Index < Lines.count - 1
            {
                let Ending = String(WriteMe.suffix(1))
                if Ending != "\n"
                {
                    WriteMe = WriteMe + "\n"
                }
            }
            FinalContents = FinalContents + WriteMe
            Index = Index + 1
        }
        
        //Write results back to the file system.
        print("Writing results to \((ReadmeFileURL)!)")
        let Contents: NSString = FinalContents as NSString
        do
        {
            try Contents.write(toFile: ReadmeFileURL!.path, atomically: true, encoding: String.Encoding.utf8.rawValue)
        }
        catch
        {
            print(error)
        }
    }
    else
    {
        print("Did not find line to modify in \((ReadmeFileURL)!).")
    }
}
else
{
    print("No README.md file found.")
}

print("VersionUpdater completed.")
