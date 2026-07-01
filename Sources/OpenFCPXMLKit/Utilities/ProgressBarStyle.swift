//
//  ProgressBarStyle.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Style configuration for CLI progress bars (TQDM-inspired).
//

import Foundation

/// Style configuration for the progress bar.
public struct ProgressBarStyle: Sendable {

    /// Format of the progress bar output.
    public enum BarFormat: Sendable {
        case standard
        case simple
        case custom(String)

        var format: String {
            switch self {
            case .standard:
                return "{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}{postfix}]"
            case .simple:
                return "{l_bar}{bar}| {percentage}"
            case let .custom(format):
                return format
            }
        }
    }

    /// ANSI colors for terminal output.
    public enum Color: String, Sendable {
        case black = "\u{001B}[30m"
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case magenta = "\u{001B}[35m"
        case cyan = "\u{001B}[36m"
        case white = "\u{001B}[37m"
        case reset = "\u{001B}[0m"
    }

    /// Bar format.
    public var barFormat: BarFormat
    /// Separator between percentage and bar.
    public var barSeparator: String
    /// Left bracket.
    public var leftBracket: String
    /// Right bracket.
    public var rightBracket: String
    /// Character for empty segment.
    public var emptyFill: String
    /// Character for filled segment.
    public var fill: String
    /// Bar width (characters); nil uses default.
    public var ncols: Int?
    /// Unit scale for display.
    public var unitScale: Double
    /// Unit divisor for display.
    public var unitDivisor: Double
    /// Optional bar color.
    public var barColor: Color?
    /// Optional description color.
    public var descColor: Color?

    /// Default style.
    public static let `default` = ProgressBarStyle(
        barFormat: .standard,
        barSeparator: " ",
        leftBracket: "[",
        rightBracket: "]",
        emptyFill: "░",
        fill: "█",
        ncols: nil,
        unitScale: 1.0,
        unitDivisor: 1.0,
        barColor: nil,
        descColor: nil
    )

    public init(
        barFormat: BarFormat = .standard,
        barSeparator: String = " ",
        leftBracket: String = "[",
        rightBracket: String = "]",
        emptyFill: String = "░",
        fill: String = "█",
        ncols: Int? = nil,
        unitScale: Double = 1.0,
        unitDivisor: Double = 1.0,
        barColor: Color? = nil,
        descColor: Color? = nil
    ) {
        self.barFormat = barFormat
        self.barSeparator = barSeparator
        self.leftBracket = leftBracket
        self.rightBracket = rightBracket
        self.emptyFill = emptyFill
        self.fill = fill
        self.ncols = ncols
        self.unitScale = unitScale
        self.unitDivisor = unitDivisor
        self.barColor = barColor
        self.descColor = descColor
    }
}
