// lib/features/qr_code/services/qr_pdf_service.dart

import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
  /// Generate a modern, vibrant PDF for restaurants/cafes
  static Future<Uint8List> generateModernQrPdf({
    required String businessName,
    required String reviewLink,
    QrPdfTemplate template = QrPdfTemplate.vibrant,
    QrPdfSize size = QrPdfSize.a4,
  }) async {
    final pdf = pw.Document();
    
    // Load fonts
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMedium = await PdfGoogleFonts.interMedium();
    
    // Generate QR code
    final qrCode = await _generateQrCodeImage(reviewLink);
    
    // Choose template
    switch (template) {
      case QrPdfTemplate.vibrant:
        pdf.addPage(_buildVibrantTemplate(
          businessName: businessName,
          qrCode: qrCode,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontMedium: fontMedium,
          size: size,
        ));
        break;
      case QrPdfTemplate.modern:
        pdf.addPage(_buildModernTemplate(
          businessName: businessName,
          qrCode: qrCode,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontMedium: fontMedium,
          size: size,
        ));
        break;
      case QrPdfTemplate.elegant:
        pdf.addPage(_buildElegantTemplate(
          businessName: businessName,
          qrCode: qrCode,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontMedium: fontMedium,
          size: size,
        ));
        break;
      case QrPdfTemplate.minimal:
        pdf.addPage(_buildMinimalTemplate(
          businessName: businessName,
          qrCode: qrCode,
          fontRegular: fontRegular,
          fontBold: fontBold,
          fontMedium: fontMedium,
          size: size,
        ));
        break;
    }
    
    return pdf.save();
  }
  
  /// Generate QR code as image
  static Future<pw.ImageProvider> _generateQrCodeImage(String data) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );
      
      // Create a custom painter to generate the image
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
      
      return pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error generating QR code: $e');
      rethrow;
    }
  }
  
  /// Vibrant template perfect for restaurants and cafes
  static pw.Page _buildVibrantTemplate({
    required String businessName,
    required pw.ImageProvider qrCode,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontMedium,
    required QrPdfSize size,
  }) {
    final pageFormat = _getPageFormat(size);
    
    return pw.Page(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return pw.Container(
          width: double.infinity,
          height: double.infinity,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
              colors: [
                PdfColor.fromHex('#FF6B6B'), // Coral
                PdfColor.fromHex('#4ECDC4'), // Turquoise
                PdfColor.fromHex('#45B7D1'), // Blue
                PdfColor.fromHex('#96CEB4'), // Mint
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: pw.Stack(
            children: [
              // Organic shapes background
              ..._buildOrganicShapes(),
              
              // Main content
              pw.Center(
                child: pw.Container(
                  width: pageFormat.width * 0.8,
                  height: pageFormat.height * 0.85,
                  padding: const pw.EdgeInsets.all(30),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(25),
                    boxShadow: const [
                      pw.BoxShadow(
                      color: PdfColor.fromInt(0x26000000), // 15% opacity black
                      blurRadius: 30,
                    ),
                    ],
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Header section
                      pw.Column(
                        children: [
                          // Main title
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: pw.BoxDecoration(
                              gradient: pw.LinearGradient(
                                colors: [
                                  PdfColor.fromHex('#FF6B6B'),
                                  PdfColor.fromHex('#4ECDC4'),
                                ],
                              ),
                              borderRadius: pw.BorderRadius.circular(30),
                            ),
                            child: pw.Text(
                              'LEAVE A REVIEW',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 28,
                                color: PdfColors.white,
                                letterSpacing: 2,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          
                          pw.SizedBox(height: 20),
                          
                          // Subtitle
                          pw.Text(
                            'How did we do?',
                            style: pw.TextStyle(
                              font: fontMedium,
                              fontSize: 24,
                              color: PdfColor.fromHex('#FF6B6B'),
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          
                          pw.SizedBox(height: 15),
                          
                          // Instructions
                          pw.Text(
                            'Scan the QR code below to share your feedback',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 16,
                              color: PdfColor.fromHex('#4ECDC4'),
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                      
                      // QR Code section
                      pw.Container(
                        padding: const pw.EdgeInsets.all(20),
                        decoration: pw.BoxDecoration(
                          gradient: pw.LinearGradient(
                            colors: [
                              PdfColor.fromHex('#F8F9FA'),
                              PdfColors.white,
                            ],
                          ),
                          borderRadius: pw.BorderRadius.circular(20),
                          border: pw.Border.all(
                            color: PdfColor.fromHex('#E9ECEF'),
                            width: 2,
                          ),
                        ),
                        child: pw.Image(
                          qrCode,
                          width: 180,
                          height: 180,
                        ),
                      ),
                      
                      // Business name and footer
                      pw.Column(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0x1A45B7D1), // Light blue with 10% opacity
                              borderRadius: pw.BorderRadius.circular(25),
                              border: pw.Border.all(
                                color: PdfColor.fromHex('#45B7D1'),
                                width: 1,
                              ),
                            ),
                            child: pw.Text(
                              businessName,
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 20,
                                color: PdfColor.fromHex('#2C3E50'),
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          
                          pw.SizedBox(height: 20),
                          
                          // Thank you message
                          pw.Text(
                            'Thank you for helping us improve! 🌟',
                            style: pw.TextStyle(
                              font: fontMedium,
                              fontSize: 14,
                              color: PdfColor.fromHex('#6C757D'),
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          
                          pw.SizedBox(height: 15),
                          
                          // RevBoost branding
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: pw.BoxDecoration(
                              gradient: pw.LinearGradient(
                                colors: [
                                  PdfColor.fromHex('#667EEA'),
                                  PdfColor.fromHex('#764BA2'),
                                ],
                              ),
                              borderRadius: pw.BorderRadius.circular(15),
                            ),
                            child: pw.Text(
                              'Powered by RevBoost',
                              style: pw.TextStyle(
                                font: fontMedium,
                                fontSize: 12,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Build organic background shapes
  static List<pw.Widget> _buildOrganicShapes() {
    return [
      // Top-left organic shape
      pw.Positioned(
        top: -50,
        left: -50,
        child: pw.Container(
          width: 200,
          height: 200,
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0x1AFFFFFF), // 10% opacity white
            borderRadius: pw.BorderRadius.circular(100),
          ),
        ),
      ),
      
      // Bottom-right organic shape
      pw.Positioned(
        bottom: -80,
        right: -80,
        child: pw.Container(
          width: 250,
          height: 250,
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0x14FFFFFF), // 8% opacity white
            borderRadius: pw.BorderRadius.circular(125),
          ),
        ),
      ),
      
      // Middle floating shape
      pw.Positioned(
        top: 150,
        right: 50,
        child: pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0x1EFFFFFF), // 12% opacity white
            borderRadius: pw.BorderRadius.circular(40),
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
  
  // Placeholder for other templates (can be implemented later)
  static pw.Page _buildModernTemplate({
    required String businessName,
    required pw.ImageProvider qrCode,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontMedium,
    required QrPdfSize size,
  }) {
    // Implementation for modern template
    return _buildVibrantTemplate(
      businessName: businessName,
      qrCode: qrCode,
      fontRegular: fontRegular,
      fontBold: fontBold,
      fontMedium: fontMedium,
      size: size,
    );
  }
  
  static pw.Page _buildElegantTemplate({
    required String businessName,
    required pw.ImageProvider qrCode,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontMedium,
    required QrPdfSize size,
  }) {
    // Implementation for elegant template
    return _buildVibrantTemplate(
      businessName: businessName,
      qrCode: qrCode,
      fontRegular: fontRegular,
      fontBold: fontBold,
      fontMedium: fontMedium,
      size: size,
    );
  }
  
  static pw.Page _buildMinimalTemplate({
    required String businessName,
    required pw.ImageProvider qrCode,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontMedium,
    required QrPdfSize size,
  }) {
    // Implementation for minimal template
    return _buildVibrantTemplate(
      businessName: businessName,
      qrCode: qrCode,
      fontRegular: fontRegular,
      fontBold: fontBold,
      fontMedium: fontMedium,
      size: size,
    );
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
      // For mobile platforms
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
  
  /// Generate multiple QR codes per page (useful for businesses with multiple locations)
  static Future<Uint8List> generateMultipleQrPdf({
    required List<String> businessNames,
    required List<String> reviewLinks,
    int perPage = 4,
  }) async {
    if (businessNames.length != reviewLinks.length) {
      throw ArgumentError('Business names and review links must have the same length');
    }
    
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    
    // Process in chunks
    for (int i = 0; i < businessNames.length; i += perPage) {
      final endIndex = math.min(i + perPage, businessNames.length);
      final currentNames = businessNames.sublist(i, endIndex);
      final currentLinks = reviewLinks.sublist(i, endIndex);
      
      // Generate QR codes for this batch
      final qrCodes = <pw.ImageProvider>[];
      for (final link in currentLinks) {
        qrCodes.add(await _generateQrCodeImage(link));
      }
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(currentNames.length, (index) {
                return pw.Container(
                  width: (PdfPageFormat.a4.width - 60) / 2, // 2 columns
                  child: _buildMiniQrCard(
                    businessName: currentNames[index],
                    qrCode: qrCodes[index],
                    fontRegular: fontRegular,
                    fontBold: fontBold,
                  ),
                );
              }),
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }
  
  /// Build mini QR card for multiple QR layout
  static pw.Widget _buildMiniQrCard({
    required String businessName,
    required pw.ImageProvider qrCode,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
        boxShadow: const [
            pw.BoxShadow(
            color: PdfColor.fromInt(0x4D808080), // 30% grey
            blurRadius: 8,
          ),
        ],
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Leave a Review',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColor.fromHex('#FF6B6B'),
            ),
            textAlign: pw.TextAlign.center,
          ),
          
          pw.SizedBox(height: 10),
          
          pw.Container(
            width: 120,
            height: 120,
            child: pw.Image(
              qrCode,
              width: 120,
              height: 120,
            ),
          ),
          
          pw.SizedBox(height: 10),
          
          pw.Column(
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Scan to share your experience',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}