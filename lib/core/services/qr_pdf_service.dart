// lib/core/services/qr_pdf_service.dart

import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum QrPdfTemplate {
  modern,
  elegant,
  vibrant,
  minimal,
}

enum QrPdfSize {
  a4,
  letter,
  businessCard,
  tableTent,
}

class QrPdfService {
  /// Generate the EXACT elegant design from the preview
  static Future<Uint8List> generateModernQrPdf({
    required String businessName,
    required String reviewLink,
    QrPdfTemplate template = QrPdfTemplate.vibrant,
    QrPdfSize size = QrPdfSize.a4,
  }) async {
    final pdfDoc = pdf.Document();
    
    // Load fonts for elegant design
    final fontRegular = await PdfGoogleFonts.crimsonTextRegular();
    final fontBold = await PdfGoogleFonts.crimsonTextBold();
    final fontItalic = await PdfGoogleFonts.crimsonTextItalic();
    
    // Generate QR code
    final qrCode = await _generateQrCodeImage("$reviewLink?source=qr");
    
    // Build the EXACT elegant design from preview
    pdfDoc.addPage(_buildExactElegantDesign(
      businessName: businessName,
      qrCode: qrCode,
      fontRegular: fontRegular,
      fontBold: fontBold,
      fontItalic: fontItalic,
      size: size,
    ));
    
    return pdfDoc.save();
  }
  
  /// Generate QR code as image
  static Future<pdf.ImageProvider> _generateQrCodeImage(String data) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 400);
      
      qrPainter.paint(canvas, size);
      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 400);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to generate QR code image');
      }
      
      return pdf.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error generating QR code: $e');
      rethrow;
    }
  }
  

/// Build the EXACT elegant design from the preview - FIXED VERSION
static pdf.Page _buildExactElegantDesign({
  required String businessName,
  required pdf.ImageProvider qrCode,
  required pdf.Font fontRegular,
  required pdf.Font fontBold,
  required pdf.Font fontItalic,
  required QrPdfSize size,
}) {
  final pageFormat = _getPageFormat(size);
  
  return pdf.Page(
    pageFormat: pageFormat,
    margin: const pdf.EdgeInsets.all(0),
    build: (pdf.Context context) {
      return pdf.Container(
        width: double.infinity,
        height: double.infinity,
        // EXACT background from preview - deep navy gradient
        decoration: pdf.BoxDecoration(
          gradient: pdf.LinearGradient(
            begin: pdf.Alignment.topLeft,
            end: pdf.Alignment.bottomRight,
            colors: [
              PdfColor.fromHex('#1a1a2e'), // Deep navy
              PdfColor.fromHex('#16213e'), // Navy blue  
              PdfColor.fromHex('#0f3460'), // Deep blue
            ],
          ),
        ),
        child: pdf.Stack(
          children: [
            // Subtle radial pattern overlay (like preview)
            pdf.Container(
              decoration: const pdf.BoxDecoration(
                gradient: pdf.RadialGradient(
                  center: pdf.Alignment.topLeft,
                  radius: 2.0,
                  colors: [
                    PdfColor.fromInt(0x08d4af37), // 3% gold overlay
                    PdfColor.fromInt(0x00000000), // transparent
                  ],
                ),
              ),
            ),
            
            // EXACT elegant border from preview
            pdf.Positioned(
              top: 20,
              left: 20,
              right: 20,
              bottom: 20,
              child: pdf.Container(
                decoration: pdf.BoxDecoration(
                  border: pdf.Border.all(
                    color: const PdfColor.fromInt(0x4Dd4af37), // 30% gold
                    width: 2,
                  ),
                  borderRadius: pdf.BorderRadius.circular(8),
                ),
              ),
            ),
            
            // EXACT corner ornaments from preview
            ..._buildExactCornerOrnaments(),
            
            // Main content - EXACTLY like preview
            pdf.Container(
              width: double.infinity,
              height: double.infinity,
              padding: const pdf.EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: pdf.Column(
                mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
                children: [
                  // Header section - EXACTLY like preview
                  pdf.Column(
                    children: [
                      // EXACT title styling from preview
                      pdf.Text(
                        'WE VALUE YOUR OPINION',
                        style: pdf.TextStyle(
                          font: fontBold,
                          fontSize: 28,
                          color: PdfColor.fromHex('#d4af37'), // Gold
                          letterSpacing: 3,
                        ),
                        textAlign: pdf.TextAlign.center,
                      ),
                      
                      pdf.SizedBox(height: 20),
                      
                      // EXACT gold divider from preview
                      pdf.Container(
                        width: 60,
                        height: 1,
                        decoration: pdf.BoxDecoration(
                          gradient: pdf.LinearGradient(
                            colors: [
                              const PdfColor.fromInt(0x00000000), // transparent
                              PdfColor.fromHex('#d4af37'),
                              const PdfColor.fromInt(0x00000000), // transparent
                            ],
                          ),
                        ),
                      ),
                      
                      pdf.SizedBox(height: 25),
                      
                      // EXACT italic subtitle from preview
                      pdf.Text(
                        'How was your experience?',
                        style: pdf.TextStyle(
                          font: fontItalic,
                          fontSize: 32,
                          color: PdfColors.white,
                        ),
                        textAlign: pdf.TextAlign.center,
                      ),
                      
                      pdf.SizedBox(height: 20),
                      
                      // EXACT instruction text from preview
                      pdf.Container(
                        width: 350,
                        child: pdf.Text(
                          'Please take a moment to scan the QR code below and share your valuable feedback with us',
                          style: pdf.TextStyle(
                            font: fontRegular,
                            fontSize: 16,
                            color: const PdfColor.fromInt(0xCCFFFFFF), // 80% white
                            height: 1.6,
                          ),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  
                  // QR section - EXACTLY like preview
                  pdf.Container(
                    padding: const pdf.EdgeInsets.all(30),
                    decoration: pdf.BoxDecoration(
                      color: const PdfColor.fromInt(0xFAFFFFFF), // 98% white
                      borderRadius: pdf.BorderRadius.circular(8),
                      boxShadow: [
                        const pdf.BoxShadow(
                          color: PdfColor.fromInt(0x1A000000), // 10% black
                          blurRadius: 35,
                        ),
                        const pdf.BoxShadow(
                          color: PdfColor.fromInt(0x14000000), // 8% black
                          blurRadius: 15,
                        ),
                      ],
                      border: pdf.Border.all(
                        color: const PdfColor.fromInt(0x33d4af37), // 20% gold
                        width: 1,
                      ),
                    ),
                    child: pdf.Image(
                      qrCode,
                      width: 200,
                      height: 200,
                    ),
                  ),
                  
                  // FIXED Footer section
                  pdf.Column(
                    children: [
                      // FIXED business name styling - better visibility
                      pdf.Container(
                        padding: const pdf.EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: pdf.BoxDecoration(
                          gradient: pdf.LinearGradient(
                            colors: [
                              PdfColor.fromHex('#d4af37'), // Full gold
                              PdfColor.fromHex('#b8941f'), // Darker gold
                            ],
                          ),
                          borderRadius: pdf.BorderRadius.circular(8),
                          border: pdf.Border.all(
                            color: PdfColor.fromHex('#d4af37'),
                            width: 2,
                          ),
                          boxShadow: [
                            const pdf.BoxShadow(
                              color: PdfColor.fromInt(0x40d4af37), // 25% gold glow
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: pdf.Text(
                          businessName,
                          style: pdf.TextStyle(
                            font: fontBold,
                            fontSize: 26,
                            color: PdfColor.fromHex('#1a1a2e'), // Dark navy text for contrast
                            letterSpacing: 1.5,
                          ),
                          textAlign: pdf.TextAlign.center,
                        ),
                      ),
                      
                      pdf.SizedBox(height: 25),
                      
                      // EXACT gold divider from preview
                      pdf.Container(
                        width: 60,
                        height: 1,
                        decoration: pdf.BoxDecoration(
                          gradient: pdf.LinearGradient(
                            colors: [
                              const PdfColor.fromInt(0x00000000), // transparent
                              PdfColor.fromHex('#d4af37'),
                              const PdfColor.fromInt(0x00000000), // transparent
                            ],
                          ),
                        ),
                      ),
                      
                      pdf.SizedBox(height: 20),
                      
                      // EXACT thank you message from preview
                      pdf.Text(
                        'Thank you for choosing us',
                        style: pdf.TextStyle(
                          font: fontRegular,
                          fontSize: 16,
                          color: const PdfColor.fromInt(0xE6FFFFFF), // 90% white - brighter
                        ),
                        textAlign: pdf.TextAlign.center,
                      ),
                      
                      // pdf.SizedBox(height: 8),
                      
                      // // FIXED stars - better visibility
                      // pdf.Text(
                      //   '⭐⭐⭐⭐⭐',
                      //   style: pdf.TextStyle(
                      //     font: fontBold,
                      //     fontSize: 20,
                      //     color: PdfColor.fromHex('#d4af37'), // Bright gold
                      //     letterSpacing: 6,
                      //   ),
                      //   textAlign: pdf.TextAlign.center,
                      // ),
                      
                      pdf.SizedBox(height: 8),
                      
                      pdf.Text(
                        'Your feedback helps us serve you better',
                        style: pdf.TextStyle(
                          font: fontRegular,
                          fontSize: 16,
                          color: const PdfColor.fromInt(0xE6FFFFFF), // 90% white - brighter
                        ),
                        textAlign: pdf.TextAlign.center,
                      ),
                      
                      pdf.SizedBox(height: 25),
                      
                      // FIXED branding - better visibility
                      pdf.Container(
                        padding: const pdf.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: pdf.BoxDecoration(
                          gradient: const pdf.LinearGradient(
                            colors: [
                              PdfColor.fromInt(0x40070606), // 25% white
                              PdfColor.fromInt(0x26251212), // 15% white
                            ],
                          ),
                          border: pdf.Border.all(
                            color: const PdfColor.fromInt(0x66FFFFFF), // 40% white border
                            width: 1,
                          ),
                          borderRadius: pdf.BorderRadius.circular(6),
                        ),
                        child: pdf.Text(
                          'POWERED BY REVBOOSTAPP',
                          style: pdf.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            color: PdfColors.white, // Full white for visibility
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
  /// Build EXACT corner ornaments from preview
  static List<pdf.Widget> _buildExactCornerOrnaments() {
    final goldColor = PdfColor.fromHex('#d4af37');
    
    return [
      // Top-left
      pdf.Positioned(
        top: 30,
        left: 30,
        child: pdf.Container(
          width: 40,
          height: 40,
          decoration: pdf.BoxDecoration(
            border: pdf.Border(
              top: pdf.BorderSide(color: goldColor, width: 2),
              left: pdf.BorderSide(color: goldColor, width: 2),
            ),
          ),
        ),
      ),
      
      // Top-right
      pdf.Positioned(
        top: 30,
        right: 30,
        child: pdf.Container(
          width: 40,
          height: 40,
          decoration: pdf.BoxDecoration(
            border: pdf.Border(
              top: pdf.BorderSide(color: goldColor, width: 2),
              right: pdf.BorderSide(color: goldColor, width: 2),
            ),
          ),
        ),
      ),
      
      // Bottom-left
      pdf.Positioned(
        bottom: 30,
        left: 30,
        child: pdf.Container(
          width: 40,
          height: 40,
          decoration: pdf.BoxDecoration(
            border: pdf.Border(
              bottom: pdf.BorderSide(color: goldColor, width: 2),
              left: pdf.BorderSide(color: goldColor, width: 2),
            ),
          ),
        ),
      ),
      
      // Bottom-right
      pdf.Positioned(
        bottom: 30,
        right: 30,
        child: pdf.Container(
          width: 40,
          height: 40,
          decoration: pdf.BoxDecoration(
            border: pdf.Border(
              bottom: pdf.BorderSide(color: goldColor, width: 2),
              right: pdf.BorderSide(color: goldColor, width: 2),
            ),
          ),
        ),
      ),
    ];
  }
  
  /// Get page format based on size
  static PdfPageFormat _getPageFormat(QrPdfSize size) {
    switch (size) {
      case QrPdfSize.a4:
        return PdfPageFormat.a4;
      case QrPdfSize.letter:
        return PdfPageFormat.letter;
      case QrPdfSize.businessCard:
        return const PdfPageFormat(3.5 * PdfPageFormat.inch, 2 * PdfPageFormat.inch);
      case QrPdfSize.tableTent:
        return const PdfPageFormat(5 * PdfPageFormat.inch, 3.5 * PdfPageFormat.inch);
    }
  }
  
  /// Print or download PDF
  static Future<void> printOrDownloadPdf({
    required Uint8List pdfBytes,
    required String fileName,
    bool download = false,
  }) async {
    if (kIsWeb) {
      if (download) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      }
    } else {
      if (download) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      }
    }
  }
  
  /// Generate multiple QR codes per page
  static Future<Uint8List> generateMultipleQrPdf({
    required List<String> businessNames,
    required List<String> reviewLinks,
    int perPage = 2,
  }) async {
    if (businessNames.length != reviewLinks.length) {
      throw ArgumentError('Business names and review links must have the same length');
    }
    
    final pdfDoc = pdf.Document();
    final fontRegular = await PdfGoogleFonts.crimsonTextRegular();
    final fontBold = await PdfGoogleFonts.crimsonTextBold();
    
    for (int i = 0; i < businessNames.length; i += perPage) {
      final endIndex = math.min(i + perPage, businessNames.length);
      final currentNames = businessNames.sublist(i, endIndex);
      final currentLinks = reviewLinks.sublist(i, endIndex);
      
      final qrCodes = <pdf.ImageProvider>[];
      for (final link in currentLinks) {
        qrCodes.add(await _generateQrCodeImage(link));
      }
      
      pdfDoc.addPage(
        pdf.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pdf.EdgeInsets.all(40),
          build: (context) {
            return pdf.Column(
              children: List.generate(currentNames.length, (index) {
                return pdf.Expanded(
                  child: pdf.Container(
                    margin: const pdf.EdgeInsets.symmetric(vertical: 20),
                    child: _buildElegantMiniCard(
                      businessName: currentNames[index],
                      qrCode: qrCodes[index],
                      fontRegular: fontRegular,
                      fontBold: fontBold,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      );
    }
    
    return pdfDoc.save();
  }
  
  /// Build elegant mini card
  static pdf.Widget _buildElegantMiniCard({
    required String businessName,
    required pdf.ImageProvider qrCode,
    required pdf.Font fontRegular,
    required pdf.Font fontBold,
  }) {
    return pdf.Container(
      padding: const pdf.EdgeInsets.all(30),
      decoration: pdf.BoxDecoration(
        gradient: pdf.LinearGradient(
          colors: [
            PdfColor.fromHex('#1a1a2e'),
            PdfColor.fromHex('#16213e'),
          ],
        ),
        borderRadius: pdf.BorderRadius.circular(12),
        border: pdf.Border.all(
          color: PdfColor.fromHex('#d4af37'),
          width: 1,
        ),
      ),
      child: pdf.Row(
        children: [
          pdf.Container(
            padding: const pdf.EdgeInsets.all(15),
            decoration: pdf.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pdf.BorderRadius.circular(8),
              border: pdf.Border.all(
                color: PdfColor.fromHex('#d4af37'),
                width: 1,
              ),
            ),
            child: pdf.Image(qrCode, width: 120, height: 120),
          ),
          pdf.SizedBox(width: 30),
          pdf.Expanded(
            child: pdf.Column(
              crossAxisAlignment: pdf.CrossAxisAlignment.start,
              mainAxisAlignment: pdf.MainAxisAlignment.center,
              children: [
                pdf.Text(
                  'WE VALUE YOUR OPINION',
                  style: pdf.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: PdfColor.fromHex('#d4af37'),
                    letterSpacing: 1,
                  ),
                ),
                pdf.SizedBox(height: 10),
                pdf.Text(
                  businessName,
                  style: pdf.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: PdfColors.white,
                  ),
                ),
                pdf.SizedBox(height: 10),
                pdf.Text(
                  'Scan to share your experience',
                  style: pdf.TextStyle(
                    font: fontRegular,
                    fontSize: 12,
                    color: const PdfColor.fromInt(0xCCFFFFFF), // 80% white
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}