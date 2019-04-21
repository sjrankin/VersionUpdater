//
//  main.swift
//  VersionUpdater
//
//  Created by Stuart Rankin on 2/24/18.
//  Copyright © 2018 Stuart Rankin. All rights reserved.
//

import Foundation

enum SpecificLines
{
    case BuildNumber
    case BuildIncrement
    case BuildDate
    case BuildTime
    case BuildID
}

let Months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

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
    }
}

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

let Quote = "\""
let Now = Date()
let Cal = Calendar.current
let Arguments = CommandLine.arguments

var VersionFileName = "Versioning.swift"
var FinalURL: URL!
if CommandLine.argc > 1
{
    VersionFileName = CommandLine.arguments[1]
    FinalURL = URL(string: VersionFileName)!
}
else
{
    //let CurrentDirectory = FileManager.default.currentDirectoryPath
    let CurrentDirectory = URL(string: FileManager.default.currentDirectoryPath)
    
    FinalURL = CurrentDirectory?.appendingPathComponent(VersionFileName)
    //FinalURL = CurrentDirectory.appending(VersionFileName)
}
if !FileManager.default.fileExists(atPath: FinalURL.path)
{
    print("Cannot find anything to update at \(FinalURL!).")
    exit(EXIT_FAILURE)
}

var Lines: [String]!
print("Attempting to read \(FinalURL.path)")
do
{
    let blob = try String(contentsOfFile: FinalURL.path, encoding: .utf8)
    Lines = blob.components(separatedBy: .newlines)
    print("Read \(Lines.count) lines in \(FinalURL)")
}
catch
{
    print(error)
    exit(EXIT_FAILURE)
}
var Scratch: [String] = [String]()
for Line in Lines
{
    Scratch.append(Line.replacingOccurrences(of: "\r\n", with: ""))
}
Lines?.removeAll()
Lines = Scratch

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

print("Writing results to \(FinalURL)")
let Fred: NSString = FinalContents as NSString
do
{
    try Fred.write(toFile: FinalURL.path, atomically: true, encoding: String.Encoding.utf8.rawValue)
}
catch
{
    print(error)
}

