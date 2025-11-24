import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';

/// Servicio para generar recibos de venta en PDF
class ReceiptService {
  /// Previsualiza el recibo en pantalla
  static Future<void> previewReceipt({
    required SaleData sale,
    required List<SaleDetailData> details,
    Map<int, String> productNames = const {},
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    final pdf = await _generateReceiptPdf(
      sale: sale,
      details: details,
      productNames: productNames,
      storeName: storeName ?? 'Mi Tienda',
      storeAddress: storeAddress,
      storePhone: storePhone,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recibo_${sale.saleNumber ?? sale.id}',
    );
  }

  /// Descarga el recibo como PDF al almacenamiento del dispositivo
  static Future<String> downloadReceipt({
    required SaleData sale,
    required List<SaleDetailData> details,
    Map<int, String> productNames = const {},
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    final pdf = await _generateReceiptPdf(
      sale: sale,
      details: details,
      productNames: productNames,
      storeName: storeName ?? 'Mi Tienda',
      storeAddress: storeAddress,
      storePhone: storePhone,
    );

    // Obtener directorio de descargas
    Directory? directory;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        directory = downloadDir;
      } else {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final fileName = 'Recibo_${sale.saleNumber ?? sale.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final filePath = '${directory?.path ?? '/storage/emulated/0/Download'}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  /// Comparte el recibo como PDF (mantiene compatibilidad)
  static Future<void> shareReceipt({
    required SaleData sale,
    required List<SaleDetailData> details,
    Map<int, String> productNames = const {},
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    final pdf = await _generateReceiptPdf(
      sale: sale,
      details: details,
      productNames: productNames,
      storeName: storeName ?? 'Mi Tienda',
      storeAddress: storeAddress,
      storePhone: storePhone,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Recibo_${sale.saleNumber ?? sale.id}.pdf',
    );
  }

  /// Genera el documento PDF del recibo
  static Future<pw.Document> _generateReceiptPdf({
    required SaleData sale,
    required List<SaleDetailData> details,
    Map<int, String> productNames = const {},
    required String storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Encabezado de la tienda
              pw.Text(
                storeName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (storeAddress != null)
                pw.Text(
                  storeAddress,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              if (storePhone != null)
                pw.Text(
                  'Tel: $storePhone',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // Información de la venta
              pw.Text(
                'RECIBO DE VENTA',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'N°: ${sale.saleNumber ?? sale.id}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Fecha: ${dateFormat.format(sale.saleDate)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),

              // Datos del cliente
              if (sale.customerName != null) ...[
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cliente: ${sale.customerName}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      if (sale.customerDocument != null)
                        pw.Text(
                          'NIT/CI: ${sale.customerDocument}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (sale.customerPhone != null)
                        pw.Text(
                          'Tel: ${sale.customerPhone}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // Encabezado de productos
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Producto',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Cant.',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'P.Unit',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Subtotal',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.3),

              // Lista de productos
              ...details.map((detail) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            productNames[detail.productVariantId] ?? 'Producto #${detail.productVariantId}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            '${detail.quantity}',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            detail.unitPrice.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            detail.subtotal.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Bs. ${sale.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Método de pago
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Método de pago:',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    sale.paymentMethod,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),

              // Pie del recibo
              pw.Text(
                '¡Gracias por su compra!',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Este documento es su comprobante de compra',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
