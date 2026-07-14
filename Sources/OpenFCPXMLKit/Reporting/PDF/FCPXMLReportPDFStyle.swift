//
//  FCPXMLReportPDFStyle.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Minimal visual constants for PDF report export.
//

import CoreGraphics
import Foundation

enum FCPXMLReportPDFStyle {
    // MARK: - Page layout
    
    /// ISO 216 A4 landscape (297 × 210 mm) in PDF points (72 pt/in).
    static let pageSize = CGSize(width: 841.89, height: 595.28)
    
    /// Outer margin on all four sides of every page.
    static let margin: CGFloat = 36
    
    /// Height reserved for the running header band (project name and sheet title).
    static let headerBandHeight: CGFloat = 32
    
    /// Height reserved for the running footer band (branding and page number).
    static let footerBandHeight: CGFloat = 32
    
    /// Vertical gap between the footer rule line and footer text baseline.
    static let footerRuleToTextSpacing: CGFloat = 10
    
    /// Space after a section title block before table content begins.
    static let sectionSpacing: CGFloat = 20
    
    /// Space after a completed table before the next block on the same page.
    static let tableSpacing: CGFloat = 12
    
    /// Width of the coloured stripe beside the running header for sheet grouping.
    static let sheetAccentStripeWidth: CGFloat = 4
    
    /// TOC row colour chip size (accent palette; matches content-page sheet index).
    static let tocColorChipSize: CGFloat = 8
    
    /// Horizontal gap between the TOC colour chip and the row index numeral.
    static let tocColorChipTrailingGap: CGFloat = 4
    
    /// Corner radius for the TOC colour chip (near-square swatch).
    static let tocColorChipCornerRadius: CGFloat = 1.5
    
    // MARK: - Typography (Menlo / Menlo-Bold)
    
    /// Cover page — project name (`drawCoverPage`).
    static let coverTitleFontSize: CGFloat = 24
    
    /// Cover page — event name, generated-on timestamp, and branding line.
    static let coverSubtitleFontSize: CGFloat = 13
    
    /// Cover info box — “About This PDF Export” heading.
    static let coverInfoTitleFontSize: CGFloat = 10
    
    /// Cover info box — wrapped guidance paragraph body text.
    static let coverInfoBodyFontSize: CGFloat = 8.5
    
    /// Inner padding for the cover info box on all sides.
    static let coverInfoBoxPadding: CGFloat = 12
    
    /// Line spacing between wrapped lines inside the cover info box body.
    static let coverInfoLineSpacing: CGFloat = 4
    
    /// Space between the info box title and body, and between wrapped paragraphs.
    static let coverInfoParagraphSpacing: CGFloat = 8
    
    /// Running header — project name (bold) and sheet title / column-set label (regular).
    static let runningHeaderFontSize: CGFloat = 9
    
    /// Running footer — export branding and page number.
    static let runningFooterFontSize: CGFloat = 8
    
    /// Content pages — primary section title (workbook sheet name on the first page of a section).
    static let sectionTitleFontSize: CGFloat = 14
    
    /// Content pages — secondary heading (e.g. “Role Durations”, missing-media title).
    static let subsectionTitleFontSize: CGFloat = 11
    
    /// Table column headers — black header row (bold).
    static let headerFontSize: CGFloat = 8
    
    /// Table body cells, table of contents rows, summary metrics, and standalone body lines.
    static let bodyFontSize: CGFloat = 8
    
    /// Summary sheet — project title rendered above role-duration metrics.
    static let summaryTitleFontSize: CGFloat = 13
    
    // MARK: - Table layout
    
    /// Height of one table data row (drives vertical pagination).
    static let rowHeight: CGFloat = 16
    
    /// Height of the black table header row.
    static let headerRowHeight: CGFloat = 20
    
    /// Horizontal inset inside each table cell before text is drawn.
    static let cellPadding: CGFloat = 4
    
    /// Minimum column width when chunking wide tables horizontally.
    static let minColumnWidth: CGFloat = 36
    
    /// Maximum packed column width used when deciding horizontal chunk breaks.
    /// After a chunk's columns are chosen, leftover page width is redistributed
    /// and columns may grow beyond this value (e.g. when many columns are excluded).
    static let maxColumnWidth: CGFloat = 140
    
    // MARK: - Derived layout
    
    /// Y position of the running header rule; top edge of the per-sheet tinted content zone.
    static var headerRuleY: CGFloat {
        margin + headerBandHeight
    }
    
    /// Y position of the running footer rule; bottom edge of the per-sheet tinted content zone.
    static var footerRuleY: CGFloat {
        pageSize.height - margin - footerBandHeight
    }
    
    /// Usable width for tables and cover info box (page width minus side margins).
    static var contentWidth: CGFloat {
        pageSize.width - (margin * 2)
    }
    
    /// Y origin where table and body content begins below the header rule.
    static var contentTop: CGFloat {
        headerRuleY + 6
    }
    
    /// Y limit above the footer rule where table and body content must stop.
    static var contentBottom: CGFloat {
        footerRuleY - 4
    }
    
    /// Full-width per-sheet tint between the header rule and footer rule (content zone only).
    static var contentAreaRect: CGRect {
        CGRect(
            x: 0,
            y: headerRuleY,
            width: pageSize.width,
            height: footerRuleY - headerRuleY
        )
    }
    
    // MARK: - Colours
    
    private static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    /// Default body and table data text (near-black).
    static let textColor = CGColor(colorSpace: rgbColorSpace, components: [0.12, 0.12, 0.12, 1])!
    
    /// Secondary text — cover subtitles, running header sheet label, footer, summary metrics.
    static let mutedTextColor = CGColor(colorSpace: rgbColorSpace, components: [0.45, 0.45, 0.45, 1])!
    
    /// Table header row fill (matches Excel black header background).
    static let headerBackgroundColor = CGColor(colorSpace: rgbColorSpace, components: [0, 0, 0, 1])!
    
    /// Table header row text (white on black).
    static let headerTextColor = CGColor(colorSpace: rgbColorSpace, components: [1, 1, 1, 1])!
    
    /// Horizontal rules marking the top and bottom of the per-sheet tinted content zone.
    static let ruleColor = CGColor(colorSpace: rgbColorSpace, components: [0.82, 0.82, 0.82, 1])!
    
    /// Media Summary missing-media file paths (matches Excel red path text).
    static let missingMediaTextColor = CGColor(colorSpace: rgbColorSpace, components: [0.78, 0.16, 0.16, 1])!
    
    /// Page background outside the per-sheet content tint.
    static let pageBackgroundColor = CGColor(colorSpace: rgbColorSpace, components: [1, 1, 1, 1])!
    
    /// Cover info box fill.
    static let coverInfoBoxBackgroundColor = CGColor(
        colorSpace: rgbColorSpace,
        components: [0.97, 0.97, 0.98, 1]
    )!
    
    /// Cover info box border stroke.
    static let coverInfoBoxBorderColor = CGColor(colorSpace: rgbColorSpace, components: [0.86, 0.86, 0.88, 1])!
    
    // MARK: - Per-sheet palettes
    
    /// Subtle content-area background tints cycled by workbook sheet index.
    private static let sheetContentPalette: [(CGFloat, CGFloat, CGFloat)] = [
        (0.93, 0.96, 1.00),
        (0.92, 0.98, 0.93),
        (1.00, 0.95, 0.90),
        (0.96, 0.93, 1.00),
        (0.98, 0.98, 0.90),
        (0.90, 0.96, 0.98),
        (0.98, 0.92, 0.95),
        (0.94, 0.98, 0.96),
        (0.97, 0.94, 0.90),
        (0.91, 0.94, 0.99),
    ]
    
    /// Header accent stripe colours cycled by workbook sheet index.
    private static let sheetAccentPalette: [(CGFloat, CGFloat, CGFloat)] = [
        (0.55, 0.72, 0.95),
        (0.45, 0.78, 0.52),
        (0.95, 0.62, 0.38),
        (0.68, 0.52, 0.88),
        (0.82, 0.78, 0.28),
        (0.38, 0.72, 0.82),
        (0.88, 0.48, 0.62),
        (0.42, 0.78, 0.68),
        (0.90, 0.68, 0.38),
        (0.48, 0.62, 0.90),
    ]
    
    /// Content-area tint for every page in a spanning sheet (column chunks and continuations).
    static func sheetContentBackgroundColor(forSheetIndex sheetIndex: Int) -> CGColor {
        let components = sheetContentPalette[sheetIndex % sheetContentPalette.count]
        return CGColor(
            colorSpace: rgbColorSpace,
            components: [components.0, components.1, components.2, 1]
        )!
    }
    
    /// Left header accent stripe matching the sheet group colour.
    static func sheetAccentColor(forSheetIndex sheetIndex: Int) -> CGColor {
        let components = sheetAccentPalette[sheetIndex % sheetAccentPalette.count]
        return CGColor(
            colorSpace: rgbColorSpace,
            components: [components.0, components.1, components.2, 1]
        )!
    }
    
    // MARK: - Fonts
    
    /// Regular body font — all non-bold PDF text.
    static let regularFontName = "Menlo"
    
    /// Bold font — cover title, section headings, and table column headers.
    static let boldFontName = "Menlo-Bold"
}
