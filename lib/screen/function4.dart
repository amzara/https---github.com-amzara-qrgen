import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: function4(),
    );
  }
}

class function4 extends StatefulWidget {
  @override
  _QRCodeGeneratorState createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<function4> {
  TextEditingController domainController = TextEditingController();
  List<Map<String, String>> qrCodes = [];
  File? _selectedFile;
  bool displayQR = false;

  Future<void> _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected file: ${_selectedFile!.path}'),
            duration: Duration(milliseconds: 900),
          ),
        );
        _selectedFile = File(result.files.single.path!);
      });
    } else {
      // User canceled the picker
    }
  }

  Future<void> generateQRCodesAndPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(milliseconds: 500),
      ),
    );
    String domain = domainController.text;

    if (_selectedFile != null) {
      List<List<dynamic>> csvData = await readAsLines(_selectedFile!);
      qrCodes.clear();

      for (var row in csvData.skip(1)) {
        int extension = row[0]; // Assuming extension is in the first column
        await fetchData(extension, domain);
      }

      // Generate PDF after fetching QR codes
      generatePdf();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No file selected'),
          content: Text('Please select a CSV file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> generateQRCodes() async {
    String domain = domainController.text;

    if (_selectedFile != null) {
      List<List<dynamic>> csvData = await readAsLines(_selectedFile!);
      qrCodes.clear();

      for (var row in csvData.skip(1)) {
        int extension = row[0]; // Assuming extension is in the first column
        await fetchData(extension, domain);
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No file selected'),
          content: Text('Please select a CSV file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
    displayQR = true;
  }

  Future<List<List<dynamic>>> readAsLines(File file) async {
    String contents = await file.readAsString();
    return CsvToListConverter().convert(contents);
  }

  Future<void> fetchData(int extension, String domain) async {
    String url =
        'https://10.16.1.213/backend/crp2.php?ext=$extension&domain=$domain';
    var response = await http.get(Uri.parse(url));
    setState(() {
      String apiResponse = response.body;
      String? extractedImgUrl = newCustomFunction(apiResponse);
      if (extractedImgUrl != null) {
        qrCodes.add({
          'url': extractedImgUrl,
          'label': 'QR Code for Extension $extension', // Label for the QR code
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR image not found for extension $extension'),
            duration: Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  String? newCustomFunction(String? html) {
    int? srcIndex = html!.indexOf('src=');

    if (srcIndex != null && srcIndex != -1) {
      int urlStartIndex = srcIndex + 5;
      int? urlEndIndex = html?.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html?.indexOf('"', urlStartIndex);
      }

      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        return "https://10.16.1.213/backend/$imageUrl";
      }
    }

    return null;
  }

  Future<void> copyImageToClipboard(String extractedImgUrl) async {
    final bytes = await _readImageBytes(extractedImgUrl);
    if (bytes != null) {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem(suggestedName: 'QRCode.png');
        item.add(Formats.png(bytes));
        await clipboard.write([item]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image copied to clipboard'),
            duration: Duration(milliseconds: 300),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard is not available on this platform'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to read image'),
        ),
      );
    }
  }

  Future<Uint8List?> _readImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to fetch image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error reading image: $e');
      return null;
    }
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    final result = await ImageGallerySaver.saveImage(bytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image saved to gallery: $result'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> generatePdf() async {
    try {
      final PdfDocument document = PdfDocument();
      final double qrCodeWidth = 500;
      final double qrCodeHeight = 500;

      for (int i = 0; i < qrCodes.length; i++) {
        String imageUrl = qrCodes[i]['url'] ?? '';

        final response = await http.get(Uri.parse(imageUrl));
        final data = response.bodyBytes;
        final PdfBitmap image = PdfBitmap(data);

        document.pages.add().graphics.drawImage(
              image,
              Rect.fromLTWH(0, 50, qrCodeWidth, qrCodeHeight),
            );

        document.pages[i].graphics.drawString(
          qrCodes[i]['label'] ?? '',
          PdfStandardFont(PdfFontFamily.helvetica, 20),
          bounds: Rect.fromLTWH(
            120,
            0,
            300,
            500,
          ),
        );
      }

      final directory = await getTemporaryDirectory();
      final String tempPath = directory.path;

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      final tempFile = File('$tempPath/output_$formattedDate.pdf');
      final List<int> bytes = await document.save();
      await tempFile.writeAsBytes(bytes, flush: true);

      document.dispose();

      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final downloadsDirectory = await getDownloadsDirectory();
      final String downloadsPath = downloadsDirectory!.path;
      final String newPath = '$downloadsPath/output_$formattedDate.pdf';
      await tempFile.copy(newPath);

      print('PDF generated successfully at: $newPath');

      OpenFile.open(newPath);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.dark(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Generate QR from CSV'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: domainController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(labelText: 'Domain'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openFilePicker,
                    child: Text('Select CSV File'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: generateQRCodes,
                    child: Text('Generate QR Codes'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: generateQRCodesAndPDF,
                    child: Text('Generate PDF'),
                  ),
                  SizedBox(height: 20),
                  
                  if (displayQR == true)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: qrCodes.map((qrCode) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              qrCode['label'] ?? '', // Display label
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.network(
                                qrCode['url'] ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    copyImageToClipboard(qrCode['url'] ?? '');
                                  },
                                  child: Icon(Icons.content_copy),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final bytes = await _readImageBytes(
                                        qrCode['url'] ?? '');
                                    if (bytes != null) {
                                      await _saveImageToGallery(bytes);
                                    }
                                  },
                                  child: Icon(Icons.file_download),
                                )
                              ],
                            )
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ));
  }
}

//note for restore checkpoint