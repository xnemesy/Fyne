import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptOcrResult {
  final double? amount;
  final DateTime? date;

  ReceiptOcrResult({this.amount, this.date});
}

class OcrService {
  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();

  Future<ReceiptOcrResult?> scanReceipt() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    double? amount;
    DateTime? date;

    // Simple regex for amount (generic € or plain numbers with decimals)
    final amountRegex = RegExp(r'(\d+[.,]\d{2})');
    // Simple regex for date (DD/MM/YYYY or DD-MM-YYYY)
    final dateRegex = RegExp(r'(\d{2}[/\-]\d{2}[/\-]\d{4})');

    final lines = recognizedText.text.split('\n');
    List<double> foundAmounts = [];

    for (var line in lines) {
      // Look for totals
      if (line.toUpperCase().contains('TOTAL') || line.toUpperCase().contains('TOTALE') || line.toUpperCase().contains('EUR')) {
        final match = amountRegex.firstMatch(line);
        if (match != null) {
          final val = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          if (val != null) foundAmounts.add(val);
        }
      }
      
      // Look for date
      final dateMatch = dateRegex.firstMatch(line);
      if (dateMatch != null && date == null) {
        try {
          final parts = dateMatch.group(1)!.split(RegExp(r'[/\-]'));
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } catch (_) {}
      }
    }

    // Usually the largest amount is the total
    if (foundAmounts.isNotEmpty) {
      foundAmounts.sort();
      amount = foundAmounts.last;
    }

    return ReceiptOcrResult(amount: amount, date: date);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
