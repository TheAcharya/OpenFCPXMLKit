//
//  FCPXMLReportPDFCanvas.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	CoreGraphics PDF page drawing helpers for report export.
//

import CoreGraphics
import CoreText
import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum FCPXMLReportPDFCanvas {
    final class Builder {
        private let context: CGContext
        private var projectName = ""
        private var eventName: String?
        private var exportBrandingText = FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.brandingText
        private var copyrightLabel: String?
        private var pageNumber = 0
        private var cursorY = FCPXMLReportPDFStyle.contentTop
        private var hasOpenPage = false
        private var runningPageTitle = ""
        private var runningContentHeading: String?
        private var runningColumnPart: Int?
        private var runningColumnPartCount: Int?
        private var runningSheetColorIndex = 0
        private var runningSheetContentColor = FCPXMLReportPDFStyle.pageBackgroundColor
        private var runningSheetAccentColor = FCPXMLReportPDFStyle.pageBackgroundColor
        private var sectionStartRecorder: ((String, Int) -> Void)?
        /// When true, pagination still runs but text/glyphs are skipped (TOC measure pass).
        private var layoutOnly = false
        
        init(context: CGContext) {
            self.context = context
        }
        
        func configureDocument(
            projectName: String,
            eventName: String?,
            exportBrandingText: String,
            copyrightLabel: String? = nil,
            sectionStartRecorder: ((String, Int) -> Void)? = nil,
            layoutOnly: Bool = false
        ) {
            self.projectName = projectName
            self.eventName = eventName
            self.exportBrandingText = exportBrandingText
            self.copyrightLabel = FinalCutPro.FCPXML.ReportOptions.normalizedCopyrightLabel(copyrightLabel)
            self.sectionStartRecorder = sectionStartRecorder
            self.layoutOnly = layoutOnly
        }
        
        func reserveBlankPages(_ count: Int) {
            guard count > 0 else { return }
            for _ in 0..<count {
                beginPage(drawRunningBands: false)
                endPage()
            }
        }
        
        func drawTableOfContents(entries: [FCPXMLReportPDFSheetPlan.SheetEntry]) {
            let validEntries = entries.filter { $0.startPage > 0 }
            guard !validEntries.isEmpty else { return }
            
            let pageColumnWidth: CGFloat = 44
            // Chip + gap + index numeral inside the leading column.
            let indexColumnWidth: CGFloat = FCPXMLReportPDFStyle.cellPadding
                + FCPXMLReportPDFStyle.tocColorChipSize
                + FCPXMLReportPDFStyle.tocColorChipTrailingGap
                + 18
            let sheetColumnWidth = FCPXMLReportPDFStyle.contentWidth - pageColumnWidth - indexColumnWidth
            let columnWidths = [indexColumnWidth, sheetColumnWidth, pageColumnWidth]
            let headers = ["#", "Sheet", "Page"]
            let rowsPerPage = FCPXMLReportPDFSheetPlan.tocRowsPerPage()
            var entryOffset = 0
            
            while entryOffset < validEntries.count {
                let pageEntries = Array(validEntries.dropFirst(entryOffset).prefix(rowsPerPage))
                
                runningPageTitle = "Table of Contents"
                beginPage(drawRunningBands: true, sheetColorIndex: nil)
                cursorY = FCPXMLReportPDFStyle.contentTop
                
                if entryOffset == 0 {
                    drawSectionTitle("Table of Contents")
                } else {
                    drawContinuationTitle("Table of Contents")
                }
                
                drawTableHeaderRow(headers: headers, columnWidths: columnWidths)
                
                for (offset, entry) in pageEntries.enumerated() {
                    drawTOCTableDataRow(
                        index: entryOffset + offset + 1,
                        title: entry.title,
                        startPage: entry.startPage,
                        colorIndex: entry.colorIndex,
                        columnWidths: columnWidths
                    )
                }
                
                endPage()
                entryOffset += pageEntries.count
            }
        }
        
        func drawCoverPage(projectName: String, eventName: String?) {
            beginPage(drawRunningBands: false)
            
            drawText(
                projectName,
                x: FCPXMLReportPDFStyle.margin,
                y: FCPXMLReportPDFStyle.margin + FCPXMLReportPDFStyle.coverTitleFontSize,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: FCPXMLReportPDFStyle.coverTitleFontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            
            var y = FCPXMLReportPDFStyle.margin + FCPXMLReportPDFStyle.coverTitleFontSize + 20
            
            if let eventName, !eventName.isEmpty {
                drawText(
                    eventName,
                    x: FCPXMLReportPDFStyle.margin,
                    y: y + FCPXMLReportPDFStyle.coverSubtitleFontSize,
                    fontName: FCPXMLReportPDFStyle.regularFontName,
                    fontSize: FCPXMLReportPDFStyle.coverSubtitleFontSize,
                    color: FCPXMLReportPDFStyle.mutedTextColor
                )
                y += FCPXMLReportPDFStyle.coverSubtitleFontSize + 14
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            
            drawText(
                "Generated on \(formatter.string(from: Date()))",
                x: FCPXMLReportPDFStyle.margin,
                y: y + FCPXMLReportPDFStyle.coverSubtitleFontSize,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: FCPXMLReportPDFStyle.coverSubtitleFontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
            y += FCPXMLReportPDFStyle.coverSubtitleFontSize + 14
            
            drawText(
                exportBrandingText,
                x: FCPXMLReportPDFStyle.margin,
                y: y + FCPXMLReportPDFStyle.coverSubtitleFontSize,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: FCPXMLReportPDFStyle.coverSubtitleFontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
            y += FCPXMLReportPDFStyle.coverSubtitleFontSize + 14
            
            if let copyrightLabel {
                drawText(
                    copyrightLabel,
                    x: FCPXMLReportPDFStyle.margin,
                    y: y + FCPXMLReportPDFStyle.coverSubtitleFontSize,
                    fontName: FCPXMLReportPDFStyle.regularFontName,
                    fontSize: FCPXMLReportPDFStyle.coverSubtitleFontSize,
                    color: FCPXMLReportPDFStyle.mutedTextColor
                )
            }
            
            drawCoverInformationBox()
            
            endPage()
        }
        
        private func drawCoverInformationBox() {
            let boxX = FCPXMLReportPDFStyle.margin
            let boxWidth = FCPXMLReportPDFStyle.contentWidth
            let padding = FCPXMLReportPDFStyle.coverInfoBoxPadding
            let headerVPad = FCPXMLReportPDFStyle.coverInfoHeaderVerticalPadding
            let bodyVPad = FCPXMLReportPDFStyle.coverInfoBodyVerticalPadding
            let innerWidth = boxWidth - (padding * 2)
            let titleFontSize = FCPXMLReportPDFStyle.coverInfoTitleFontSize
            let symbolSize = FCPXMLReportPDFStyle.coverInfoSymbolSize
            let symbolGap = FCPXMLReportPDFStyle.coverInfoSymbolTitleGap
            let titleContentHeight = max(titleFontSize, symbolSize)
            let headerHeight = headerVPad * 2 + titleContentHeight
            let bodyFontSize = FCPXMLReportPDFStyle.coverInfoBodyFontSize
            let lineSpacing = FCPXMLReportPDFStyle.coverInfoLineSpacing
            let paragraphSpacing = FCPXMLReportPDFStyle.coverInfoParagraphSpacing
            
            var bodyLineCount = 0
            for paragraph in FCPXMLReportPDFCoverNotes.paragraphs {
                bodyLineCount += FCPXMLReportPDFTableLayout.wrappedLines(
                    paragraph,
                    maxWidth: innerWidth,
                    fontSize: bodyFontSize
                ).count
            }
            
            let bodyTextHeight = CGFloat(bodyLineCount) * (bodyFontSize + lineSpacing)
                + CGFloat(max(0, FCPXMLReportPDFCoverNotes.paragraphs.count - 1)) * paragraphSpacing
            let bodyHeight = bodyVPad * 2 + bodyTextHeight
            let boxHeight = headerHeight + bodyHeight
            
            let boxY = FCPXMLReportPDFStyle.pageSize.height
                - FCPXMLReportPDFStyle.margin
                - boxHeight
            
            let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
            let headerRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: headerHeight)
            let bodyRect = CGRect(
                x: boxX,
                y: boxY + headerHeight,
                width: boxWidth,
                height: bodyHeight
            )
            
            context.setFillColor(FCPXMLReportPDFStyle.headerBackgroundColor)
            context.fill(headerRect)
            context.setFillColor(FCPXMLReportPDFStyle.coverInfoBoxBackgroundColor)
            context.fill(bodyRect)
            context.setStrokeColor(FCPXMLReportPDFStyle.coverInfoBoxBorderColor)
            context.setLineWidth(0.75)
            context.stroke(boxRect)
            
            // Centre the symbol and title on the same optical midline in the header band.
            let headerMidY = boxY + headerHeight / 2
            let titleBaseline = headerMidY + titleFontSize * 0.35
            let symbolTop = headerMidY - symbolSize / 2
            
            drawSFSymbol(
                FCPXMLReportPDFCoverNotes.symbolName,
                in: CGRect(
                    x: boxX + padding,
                    y: symbolTop,
                    width: symbolSize,
                    height: symbolSize
                ),
                color: FCPXMLReportPDFStyle.headerTextColor,
                weight: .bold
            )
            
            drawText(
                FCPXMLReportPDFCoverNotes.title,
                x: boxX + padding + symbolSize + symbolGap,
                y: titleBaseline,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: titleFontSize,
                color: FCPXMLReportPDFStyle.headerTextColor
            )
            
            var cursor = bodyRect.minY + bodyVPad + bodyFontSize
            
            for (index, paragraph) in FCPXMLReportPDFCoverNotes.paragraphs.enumerated() {
                let lines = FCPXMLReportPDFTableLayout.wrappedLines(
                    paragraph,
                    maxWidth: innerWidth,
                    fontSize: bodyFontSize
                )
                
                for line in lines {
                    drawText(
                        line,
                        x: boxX + padding,
                        y: cursor,
                        fontName: FCPXMLReportPDFStyle.regularFontName,
                        fontSize: bodyFontSize,
                        color: FCPXMLReportPDFStyle.mutedTextColor
                    )
                    cursor += bodyFontSize + lineSpacing
                }
                
                if index < FCPXMLReportPDFCoverNotes.paragraphs.count - 1 {
                    cursor += paragraphSpacing
                }
            }
        }
        
        /// Draws an SF Symbol into the flipped page coordinate space.
        private func drawSFSymbol(
            _ name: String,
            in rect: CGRect,
            color: CGColor,
            weight: SFSymbolWeight = .regular
        ) {
            guard let image = Self.sfSymbolCGImage(
                named: name,
                size: max(rect.width, rect.height),
                color: color,
                weight: weight
            ) else {
                return
            }
            
            context.saveGState()
            // Page coordinates are flipped (y grows down); unflip so the glyph is upright.
            context.translateBy(x: rect.minX, y: rect.maxY)
            context.scaleBy(x: 1, y: -1)
            context.draw(image, in: CGRect(origin: .zero, size: rect.size))
            context.restoreGState()
        }
        
        private enum SFSymbolWeight {
            case regular
            case bold
            
            #if canImport(AppKit)
            var appKitWeight: NSFont.Weight {
                switch self {
                case .regular: return .regular
                case .bold: return .bold
                }
            }
            #endif
            
            #if canImport(UIKit)
            var uiKitWeight: UIImage.SymbolWeight {
                switch self {
                case .regular: return .regular
                case .bold: return .bold
                }
            }
            #endif
        }
        
        private static func sfSymbolCGImage(
            named name: String,
            size: CGFloat,
            color: CGColor,
            weight: SFSymbolWeight
        ) -> CGImage? {
            #if canImport(AppKit)
            guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
                return nil
            }
            let nsColor = NSColor(cgColor: color) ?? .secondaryLabelColor
            let config = NSImage.SymbolConfiguration(pointSize: size, weight: weight.appKitWeight)
                .applying(NSImage.SymbolConfiguration(paletteColors: [nsColor]))
            guard let image = base.withSymbolConfiguration(config) else { return nil }
            var proposed = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            return image.cgImage(forProposedRect: &proposed, context: nil, hints: nil)
            #elseif canImport(UIKit)
            let config = UIImage.SymbolConfiguration(pointSize: size, weight: weight.uiKitWeight)
            guard let image = UIImage(systemName: name, withConfiguration: config)?
                .withTintColor(UIColor(cgColor: color), renderingMode: .alwaysOriginal)
            else {
                return nil
            }
            return image.cgImage
            #else
            return nil
            #endif
        }
        
        func beginContentPage(
            pageTitle: String,
            sheetColorIndex: Int,
            contentHeading: String? = nil,
            columnPart: Int? = nil,
            columnPartCount: Int? = nil,
            repeatOnContinuation: Bool = false,
            recordsSectionStart: Bool = false
        ) {
            if hasOpenPage {
                endPage()
            }
            
            runningPageTitle = pageTitle
            runningContentHeading = contentHeading
            runningColumnPart = columnPart
            runningColumnPartCount = columnPartCount
            applySheetColors(sheetColorIndex: sheetColorIndex)
            
            beginPage(drawRunningBands: true, sheetColorIndex: sheetColorIndex)
            
            if recordsSectionStart, let sectionStartRecorder {
                sectionStartRecorder(pageTitle, pageNumber)
            }
            
            cursorY = FCPXMLReportPDFStyle.contentTop
            
            if !repeatOnContinuation {
                let heading = contentHeading ?? pageTitle
                drawSectionTitle(heading)
            } else {
                let heading = contentHeading ?? pageTitle
                drawContinuationTitle(heading)
            }
        }
        
        func endContentPage() {
            endPage()
        }
        
        func drawSectionTitle(_ title: String) {
            drawText(
                title,
                x: FCPXMLReportPDFStyle.margin,
                y: cursorY + FCPXMLReportPDFStyle.sectionTitleFontSize,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: FCPXMLReportPDFStyle.sectionTitleFontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            cursorY += FCPXMLReportPDFStyle.sectionTitleFontSize + 10
        }
        
        private func drawContinuationTitle(_ title: String) {
            drawText(
                "\(title) (continued)",
                x: FCPXMLReportPDFStyle.margin,
                y: cursorY + FCPXMLReportPDFStyle.subsectionTitleFontSize,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: FCPXMLReportPDFStyle.subsectionTitleFontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
            cursorY += FCPXMLReportPDFStyle.subsectionTitleFontSize + 8
        }
        
        func drawSubsectionTitle(_ title: String) {
            drawText(
                title,
                x: FCPXMLReportPDFStyle.margin,
                y: cursorY + FCPXMLReportPDFStyle.subsectionTitleFontSize,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: FCPXMLReportPDFStyle.subsectionTitleFontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            cursorY += FCPXMLReportPDFStyle.subsectionTitleFontSize + 8
        }
        
        func drawBodyLine(
            _ text: String,
            color: CGColor = FCPXMLReportPDFStyle.textColor,
            fontSize: CGFloat = FCPXMLReportPDFStyle.bodyFontSize
        ) {
            ensureVerticalSpace(fontSize + 8)
            drawText(
                text,
                x: FCPXMLReportPDFStyle.margin,
                y: cursorY + fontSize,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: fontSize,
                color: color
            )
            cursorY += fontSize + 8
        }
        
        func drawSummaryProjectTitle(_ title: String) {
            ensureVerticalSpace(FCPXMLReportPDFStyle.summaryTitleFontSize + 10)
            drawText(
                title,
                x: FCPXMLReportPDFStyle.margin,
                y: cursorY + FCPXMLReportPDFStyle.summaryTitleFontSize,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: FCPXMLReportPDFStyle.summaryTitleFontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            cursorY += FCPXMLReportPDFStyle.summaryTitleFontSize + 10
        }
        
        func drawTable(
            context tableContext: FCPXMLReportPDFTableRenderer.TableDrawContext,
            headers: [String],
            rows: [[String]],
            rowTextColor: CGColor = FCPXMLReportPDFStyle.textColor,
            rowTextColorForRow: ((Int, [String]) -> CGColor)? = nil,
            footerTotal: FCPXMLReportPDFTableRenderer.TableFooterTotal? = nil
        ) {
            FCPXMLReportPDFTableRenderer.drawTable(
                on: self,
                context: tableContext,
                headers: headers,
                rows: rows,
                rowTextColor: rowTextColor,
                rowTextColorForRow: rowTextColorForRow,
                footerTotal: footerTotal
            )
            cursorY += FCPXMLReportPDFStyle.tableSpacing
        }
        
        func drawTableFooterTotalRow(
            labelGlobalIndex: Int,
            valueGlobalIndex: Int,
            label: String,
            value: String,
            chunkColumnIndices: [Int],
            columnWidths: [CGFloat]
        ) {
            guard let localLabel = chunkColumnIndices.firstIndex(of: labelGlobalIndex),
                  let localValue = chunkColumnIndices.firstIndex(of: valueGlobalIndex)
            else { return }
            
            ensureVerticalSpace(
                FCPXMLReportPDFStyle.rowHeight + FCPXMLReportPDFStyle.headerRowHeight
            )
            cursorY += FCPXMLReportPDFStyle.rowHeight
            ensureVerticalSpace(FCPXMLReportPDFStyle.headerRowHeight)
            
            let originX = FCPXMLReportPDFStyle.margin
            var x = originX
            
            for (index, width) in columnWidths.enumerated() {
                if index == localLabel || index == localValue {
                    let cellRect = CGRect(
                        x: x,
                        y: cursorY,
                        width: width,
                        height: FCPXMLReportPDFStyle.headerRowHeight
                    )
                    context.setFillColor(FCPXMLReportPDFStyle.headerBackgroundColor)
                    context.fill(cellRect)
                    
                    let text = index == localLabel ? label : value
                    let display = FCPXMLReportPDFTableLayout.truncated(
                        text,
                        maxWidth: width,
                        bold: true,
                        fontSize: FCPXMLReportPDFStyle.headerFontSize
                    )
                    drawText(
                        display,
                        x: x + FCPXMLReportPDFStyle.cellPadding,
                        y: cursorY + FCPXMLReportPDFStyle.headerFontSize + 4,
                        fontName: FCPXMLReportPDFStyle.boldFontName,
                        fontSize: FCPXMLReportPDFStyle.headerFontSize,
                        color: FCPXMLReportPDFStyle.headerTextColor
                    )
                }
                x += width
            }
            
            cursorY += FCPXMLReportPDFStyle.headerRowHeight
        }
        
        func drawTableHeaderRow(headers: [String], columnWidths: [CGFloat]) {
            ensureVerticalSpace(FCPXMLReportPDFStyle.headerRowHeight)
            
            let originX = FCPXMLReportPDFStyle.margin
            let tableWidth = columnWidths.reduce(0, +)
            let rowRect = CGRect(
                x: originX,
                y: cursorY,
                width: tableWidth,
                height: FCPXMLReportPDFStyle.headerRowHeight
            )
            
            context.setFillColor(FCPXMLReportPDFStyle.headerBackgroundColor)
            context.fill(rowRect)
            
            var x = originX
            for (index, header) in headers.enumerated() {
                let width = columnWidths[index]
                let text = FCPXMLReportPDFTableLayout.truncated(
                    header,
                    maxWidth: width,
                    bold: true,
                    fontSize: FCPXMLReportPDFStyle.headerFontSize
                )
                drawText(
                    text,
                    x: x + FCPXMLReportPDFStyle.cellPadding,
                    y: cursorY + FCPXMLReportPDFStyle.headerFontSize + 4,
                    fontName: FCPXMLReportPDFStyle.boldFontName,
                    fontSize: FCPXMLReportPDFStyle.headerFontSize,
                    color: FCPXMLReportPDFStyle.headerTextColor
                )
                x += width
            }
            
            cursorY += FCPXMLReportPDFStyle.headerRowHeight
        }
        
        func drawTableDataRow(
            values: [String],
            columnWidths: [CGFloat],
            textColor: CGColor = FCPXMLReportPDFStyle.textColor
        ) {
            ensureVerticalSpace(FCPXMLReportPDFStyle.rowHeight)
            
            var x = FCPXMLReportPDFStyle.margin
            let tableWidth = columnWidths.reduce(0, +)
            
            for (index, value) in values.enumerated() {
                let width = columnWidths[index]
                let text = FCPXMLReportPDFTableLayout.truncated(
                    value,
                    maxWidth: width,
                    fontSize: FCPXMLReportPDFStyle.bodyFontSize
                )
                drawText(
                    text,
                    x: x + FCPXMLReportPDFStyle.cellPadding,
                    y: cursorY + FCPXMLReportPDFStyle.bodyFontSize + 3,
                    fontName: FCPXMLReportPDFStyle.regularFontName,
                    fontSize: FCPXMLReportPDFStyle.bodyFontSize,
                    color: textColor
                )
                x += width
            }
            
            context.setStrokeColor(FCPXMLReportPDFStyle.ruleColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: FCPXMLReportPDFStyle.margin, y: cursorY + FCPXMLReportPDFStyle.rowHeight))
            context.addLine(to: CGPoint(x: FCPXMLReportPDFStyle.margin + tableWidth, y: cursorY + FCPXMLReportPDFStyle.rowHeight))
            context.strokePath()
            
            cursorY += FCPXMLReportPDFStyle.rowHeight
        }
        
        func finishDocument() {
            if hasOpenPage {
                endPage()
            }
            context.closePDF()
        }
        
        private func ensureVerticalSpace(_ height: CGFloat) {
            guard cursorY + height > FCPXMLReportPDFStyle.contentBottom else { return }
            
            endPage()
            beginContentPage(
                pageTitle: runningPageTitle,
                sheetColorIndex: runningSheetColorIndex,
                contentHeading: runningContentHeading,
                columnPart: runningColumnPart,
                columnPartCount: runningColumnPartCount,
                repeatOnContinuation: true
            )
        }
        
        private func applySheetColors(sheetColorIndex: Int) {
            runningSheetColorIndex = sheetColorIndex
            runningSheetContentColor = FCPXMLReportPDFStyle.sheetContentBackgroundColor(
                forSheetIndex: sheetColorIndex
            )
            runningSheetAccentColor = FCPXMLReportPDFStyle.sheetAccentColor(
                forSheetIndex: sheetColorIndex
            )
        }
        
        private func beginPage(drawRunningBands: Bool, sheetColorIndex: Int? = nil) {
            pageNumber += 1
            
            var mediaBox = CGRect(origin: .zero, size: FCPXMLReportPDFStyle.pageSize)
            context.beginPage(mediaBox: &mediaBox)
            context.saveGState()
            context.translateBy(x: 0, y: FCPXMLReportPDFStyle.pageSize.height)
            context.scaleBy(x: 1, y: -1)
            hasOpenPage = true
            
            if drawRunningBands {
                if let sheetColorIndex {
                    applySheetColors(sheetColorIndex: sheetColorIndex)
                }
                drawPageChrome(includeSheetGrouping: sheetColorIndex != nil)
                drawRunningHeader()
                drawRunningFooter()
            } else {
                drawPageChrome(includeSheetGrouping: false)
            }
        }
        
        private func drawPageChrome(includeSheetGrouping: Bool) {
            context.setFillColor(FCPXMLReportPDFStyle.pageBackgroundColor)
            context.fill(CGRect(origin: .zero, size: FCPXMLReportPDFStyle.pageSize))
            
            guard includeSheetGrouping else { return }
            
            context.setFillColor(runningSheetContentColor)
            context.fill(FCPXMLReportPDFStyle.contentAreaRect)
            
            context.setFillColor(runningSheetAccentColor)
            context.fill(CGRect(
                x: FCPXMLReportPDFStyle.margin - FCPXMLReportPDFStyle.sheetAccentStripeWidth - 2,
                y: FCPXMLReportPDFStyle.margin,
                width: FCPXMLReportPDFStyle.sheetAccentStripeWidth,
                height: FCPXMLReportPDFStyle.headerBandHeight
            ))
        }
        
        private func endPage() {
            guard hasOpenPage else { return }
            context.restoreGState()
            context.endPage()
            hasOpenPage = false
        }
        
        private func drawRunningHeader() {
            let baseline = FCPXMLReportPDFStyle.margin + FCPXMLReportPDFStyle.runningHeaderFontSize
            
            drawText(
                projectName,
                x: FCPXMLReportPDFStyle.margin,
                y: baseline,
                fontName: FCPXMLReportPDFStyle.boldFontName,
                fontSize: FCPXMLReportPDFStyle.runningHeaderFontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            
            var headerRight = runningPageTitle
            if let runningColumnPart,
               let runningColumnPartCount,
               runningColumnPartCount > 1
            {
                headerRight += " · Columns \(runningColumnPart) of \(runningColumnPartCount)"
            }
            
            let rightWidth = FCPXMLReportPDFTableLayout.measuredWidth(
                headerRight,
                bold: false,
                fontSize: FCPXMLReportPDFStyle.runningHeaderFontSize
            )
            drawText(
                headerRight,
                x: max(
                    FCPXMLReportPDFStyle.margin,
                    FCPXMLReportPDFStyle.pageSize.width - FCPXMLReportPDFStyle.margin - rightWidth
                ),
                y: baseline,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: FCPXMLReportPDFStyle.runningHeaderFontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
            
            drawHorizontalRule(atY: FCPXMLReportPDFStyle.headerRuleY)
        }
        
        private func drawRunningFooter() {
            drawHorizontalRule(atY: FCPXMLReportPDFStyle.footerRuleY)
            
            let baseline = FCPXMLReportPDFStyle.footerRuleY
                + FCPXMLReportPDFStyle.footerRuleToTextSpacing
                + FCPXMLReportPDFStyle.runningFooterFontSize
            
            let usableWidth = FCPXMLReportPDFStyle.pageSize.width - (FCPXMLReportPDFStyle.margin * 2)
            let brandingFraction: CGFloat = copyrightLabel == nil ? 0.55 : 0.32
            let brandingLabel = FCPXMLReportPDFTableLayout.truncated(
                exportBrandingText,
                maxWidth: usableWidth * brandingFraction,
                fontSize: FCPXMLReportPDFStyle.runningFooterFontSize
            )
            drawText(
                brandingLabel,
                x: FCPXMLReportPDFStyle.margin,
                y: baseline,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: FCPXMLReportPDFStyle.runningFooterFontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
            
            if let copyrightLabel {
                let centerLabel = FCPXMLReportPDFTableLayout.truncated(
                    copyrightLabel,
                    maxWidth: usableWidth * 0.36,
                    fontSize: FCPXMLReportPDFStyle.runningFooterFontSize
                )
                let centerWidth = FCPXMLReportPDFTableLayout.measuredWidth(
                    centerLabel,
                    bold: false,
                    fontSize: FCPXMLReportPDFStyle.runningFooterFontSize
                )
                drawText(
                    centerLabel,
                    x: FCPXMLReportPDFStyle.margin + (usableWidth - centerWidth) / 2,
                    y: baseline,
                    fontName: FCPXMLReportPDFStyle.regularFontName,
                    fontSize: FCPXMLReportPDFStyle.runningFooterFontSize,
                    color: FCPXMLReportPDFStyle.mutedTextColor
                )
            }
            
            let pageLabel = "Page \(pageNumber)"
            let pageLabelWidth = FCPXMLReportPDFTableLayout.measuredWidth(
                pageLabel,
                bold: false,
                fontSize: FCPXMLReportPDFStyle.runningFooterFontSize
            )
            drawText(
                pageLabel,
                x: FCPXMLReportPDFStyle.pageSize.width - FCPXMLReportPDFStyle.margin - pageLabelWidth,
                y: baseline,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: FCPXMLReportPDFStyle.runningFooterFontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
        }
        
        private func drawHorizontalRule(atY y: CGFloat) {
            context.setStrokeColor(FCPXMLReportPDFStyle.ruleColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: FCPXMLReportPDFStyle.margin, y: y))
            context.addLine(to: CGPoint(
                x: FCPXMLReportPDFStyle.pageSize.width - FCPXMLReportPDFStyle.margin,
                y: y
            ))
            context.strokePath()
        }
        
        private func drawTOCTableDataRow(
            index: Int,
            title: String,
            startPage: Int,
            colorIndex: Int,
            columnWidths: [CGFloat]
        ) {
            ensureVerticalSpace(FCPXMLReportPDFStyle.rowHeight)
            
            let originX = FCPXMLReportPDFStyle.margin
            let tableWidth = columnWidths.reduce(0, +)
            let fontSize = FCPXMLReportPDFStyle.bodyFontSize
            let baseline = cursorY + fontSize + 3
            let rowRect = CGRect(
                x: originX,
                y: cursorY,
                width: tableWidth,
                height: FCPXMLReportPDFStyle.rowHeight
            )
            
            // Light content-tint wash (same palette index as the sheet's content pages).
            context.saveGState()
            context.setFillColor(
                FCPXMLReportPDFStyle.sheetContentBackgroundColor(forSheetIndex: colorIndex)
            )
            context.fill(rowRect)
            context.restoreGState()
            
            // Accent colour chip — stronger, easier to distinguish than the wash alone.
            let chipSize = FCPXMLReportPDFStyle.tocColorChipSize
            let chipX = originX + FCPXMLReportPDFStyle.cellPadding
            let chipY = cursorY + (FCPXMLReportPDFStyle.rowHeight - chipSize) / 2
            let chipRect = CGRect(x: chipX, y: chipY, width: chipSize, height: chipSize)
            context.saveGState()
            context.setFillColor(
                FCPXMLReportPDFStyle.sheetAccentColor(forSheetIndex: colorIndex)
            )
            let chipPath = CGPath(
                roundedRect: chipRect,
                cornerWidth: FCPXMLReportPDFStyle.tocColorChipCornerRadius,
                cornerHeight: FCPXMLReportPDFStyle.tocColorChipCornerRadius,
                transform: nil
            )
            context.addPath(chipPath)
            context.fillPath()
            context.restoreGState()
            
            let indexText = "\(index)"
            let indexTextX = chipX + chipSize + FCPXMLReportPDFStyle.tocColorChipTrailingGap
            drawText(
                indexText,
                x: indexTextX,
                y: baseline,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: fontSize,
                color: FCPXMLReportPDFStyle.mutedTextColor
            )
            
            let sheetX = originX + columnWidths[0]
            let sheetWidth = columnWidths[1]
            let sheetText = FCPXMLReportPDFTableLayout.truncated(
                title,
                maxWidth: sheetWidth,
                fontSize: fontSize
            )
            drawText(
                sheetText,
                x: sheetX + FCPXMLReportPDFStyle.cellPadding,
                y: baseline,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: fontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            
            let pageText = "\(startPage)"
            let pageColumnX = originX + columnWidths[0] + columnWidths[1]
            let pageColumnWidth = columnWidths[2]
            let pageTextWidth = FCPXMLReportPDFTableLayout.measuredWidth(
                pageText,
                bold: false,
                fontSize: fontSize
            )
            drawText(
                pageText,
                x: pageColumnX + pageColumnWidth - FCPXMLReportPDFStyle.cellPadding - pageTextWidth,
                y: baseline,
                fontName: FCPXMLReportPDFStyle.regularFontName,
                fontSize: fontSize,
                color: FCPXMLReportPDFStyle.textColor
            )
            
            context.setStrokeColor(FCPXMLReportPDFStyle.ruleColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: originX, y: cursorY + FCPXMLReportPDFStyle.rowHeight))
            context.addLine(to: CGPoint(x: originX + tableWidth, y: cursorY + FCPXMLReportPDFStyle.rowHeight))
            context.strokePath()
            
            cursorY += FCPXMLReportPDFStyle.rowHeight
        }
        
        private func drawText(
            _ text: String,
            x: CGFloat,
            y: CGFloat,
            fontName: String,
            fontSize: CGFloat,
            color: CGColor
        ) {
            guard !layoutOnly else { return }
            guard !text.isEmpty else { return }
            
            let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                kCTFontAttributeName as NSAttributedString.Key: font,
                kCTForegroundColorAttributeName as NSAttributedString.Key: color,
            ]
            let attributed = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributed)
            
            context.saveGState()
            context.setTextDrawingMode(.fill)
            context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(line, context)
            context.restoreGState()
        }
    }
}

