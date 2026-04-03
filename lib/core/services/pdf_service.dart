import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/meters/domain/meter.dart';

class PdfService {
  static Future<void> generateMeterReport(Meter meter) async {
    final pdf = pw.Document();

    // Load images if available
    final List<pw.MemoryImage> imageWidgets = [];
    if (!kIsWeb) {
      for (var path in meter.capturedImagePaths) {
        final file = io.File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          imageWidgets.add(pw.MemoryImage(bytes));
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(meter),
            pw.SizedBox(height: 20),
            _buildSectionTitle('CUSTOMER INFORMATION'),
            _buildInfoTable([
              ['Full Name', meter.customerName],
              ['Address', meter.address],
              ['Telephone', meter.telephone],
              ['Tariff Class', meter.tariffClass],
              ['Tariff Activity', meter.tariffActivity.name.toUpperCase()],
            ]),
            pw.SizedBox(height: 20),
            _buildSectionTitle('TECHNICAL SPECIFICATIONS'),
            _buildInfoTable([
              ['Meter ID', meter.id],
              ['Brand', meter.brand],
              ['Rating', meter.rating],
              ['Phase', meter.phase.name.toUpperCase()],
              ['Metering Type', meter.type.name.toUpperCase()],
              ['SPN Number', meter.spnNumber],
            ]),
            pw.SizedBox(height: 20),
            _buildSectionTitle('GEOLOCATION & METADATA'),
            _buildInfoTable([
              ['Geocode', meter.geocode],
              ['GPS Coordinates', meter.gpsCoordinates],
              ['Installation Date', meter.installationDate.toString().split(' ')[0]],
              ['Status', meter.status.name.toUpperCase()],
            ]),
            if (imageWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              _buildSectionTitle('CAPTURED IMAGES'),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: imageWidgets.map((img) {
                  return pw.Container(
                    width: 150,
                    height: 150,
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  );
                }).toList(),
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Meter_Report_${meter.id}.pdf',
    );
  }

  static pw.Widget _buildHeader(Meter meter) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('RPECG INSPECTION REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('Record ID: ${meter.id}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.PdfLogo(),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
      width: double.infinity,
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
      ),
    );
  }

  static pw.Widget _buildInfoTable(List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: data.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row[0], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
