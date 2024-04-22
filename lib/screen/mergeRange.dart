import 'dart:io';
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: mergeRange(),
    );
  }
}

class mergeRange extends StatefulWidget {
  @override
  _QRCodeGeneratorState createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<mergeRange> {
  TextEditingController extController1 = TextEditingController();
  TextEditingController extController2 = TextEditingController();
  TextEditingController domainController = TextEditingController();
  List<String> qrCodes = [];
  List<String> selectedExtensions = [];
  List<String> successfulExtensions = [];
  String apiResponse = '';
  bool qrCodesGenerated = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Generate QR in Number Range'),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: extController1,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Start Extension'),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: extController2,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'End Extension'),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: domainController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(labelText: 'Domain'),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await generateQRCode();
                          setState(() {
                            qrCodesGenerated = true;
                          });
                        },
                        child: Text('Generate QR Codes'),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          exportAsPDF();
                        },
                        child: Text('Export as PDF'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (qrCodesGenerated) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: qrCodes.length,
                      itemBuilder: (context, index) {
                        int extNumber = int.parse(extController1.text) + index;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Qr Code for Extension ${successfulExtensions[index]}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(
                                  qrCodes[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    copyImageToClipboard(qrCodes[index]);
                                  },
                                  child: Icon(Icons.content_copy),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: () async {
                                    final bytes =
                                        await _readImageBytes(qrCodes[index]);
                                    if (bytes != null) {
                                      await _saveImageToGallery(bytes);
                                    }
                                  },
                                  child: Icon(Icons.file_download),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ],
              )),
        ),
      ),
    );
  }

  Future<void> generateQRCode() async {
    int ext1 = int.tryParse(extController1.text) ?? 0;
    int ext2 = int.tryParse(extController2.text) ?? 0;
    String domain = domainController.text;

    setState(() {
      qrCodes.clear();
      apiResponse = '';
    });

    for (int i = ext1; i <= ext2; i++) {
      String url = 'https://10.16.1.213/backend/crp2.php?ext=$i&domain=$domain';
      var response = await http.get(Uri.parse(url));
      setState(() {
        apiResponse = response.body;

        String? extractedImgUrl = newCustomFunction(apiResponse);
        if (extractedImgUrl != null && !qrCodes.contains(extractedImgUrl)) {
          qrCodes.add(extractedImgUrl);
          successfulExtensions.add(i.toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR not found for extension $i'),
              duration: Duration(milliseconds: 300),
            ),
          );
        }
      });
    }
  }

  Future<void> exportAsPDF() async {
    if (!qrCodesGenerated) {
      // Generate QR codes if they haven't been generated yet
      await generateQRCode();
    }

    try {
      // Create a new PDF document
      PdfDocument document = PdfDocument();

      final double qrCodeWidth = 500;
      final double qrCodeHeight = 500;

      // Iterate through all QR codes and add them to the PDF
      for (int i = 0; i < successfulExtensions.length; i++) {
        // Use selectedExtensions.length as limit
        String imageUrl = qrCodes[i];

        // Load image data into PDF bitmap object
        var response = await http.get(Uri.parse(imageUrl));
        var data = response.bodyBytes;
        PdfBitmap image = PdfBitmap(data);

        // Add a page and draw the image
        var page = document.pages.add();
        page.graphics.drawImage(
          image,
          Rect.fromLTWH(0, 50, qrCodeWidth, qrCodeHeight),
        );

        // Draw the label above the image
        page.graphics.drawString(
          'Qr Code for Extension ${successfulExtensions[i]}',
          PdfStandardFont(PdfFontFamily.helvetica, 20),
          bounds: Rect.fromLTWH(
            120, // x position
            0, // y position
            300, // width of the text box
            50, // height of the text box
          ),
        );
      }

      // Save the document
      final List<int> bytes = await document.save();
      // Dispose the document
      document.dispose();

      // Get the directory for saving PDF
      final directory = await getTemporaryDirectory();
      final String tempPath = directory.path;

      var now = DateTime.now();
      // Format date and time as a string
      var formattedDateTime = DateFormat('yyyyMMdd_HHmmss').format(now);

      // Write PDF bytes to a temporary file
      final tempFile = File('$tempPath/output_$formattedDateTime.pdf');
      await tempFile.writeAsBytes(bytes, flush: true);

      // Get permission to access the downloads directory
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Move the file to the downloads directory
      final downloadsDirectory = await getDownloadsDirectory();
      final String downloadsPath = downloadsDirectory!.path;
      final String newPath = '$downloadsPath/output_$formattedDateTime.pdf';
      await tempFile.copy(newPath);

      print('PDF generated successfully at: $newPath');

      // Open the PDF file
      OpenFile.open(newPath);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  String? newCustomFunction(String? html) {
    int? srcIndex = html!.indexOf('src=');
    if (srcIndex == null || srcIndex == -1) {
      return null;
    }
    int urlStartIndex = srcIndex + 5;
    int? urlEndIndex = html?.indexOf("'", urlStartIndex);
    if (urlEndIndex == null || urlEndIndex == -1) {
      urlEndIndex = html?.indexOf('"', urlStartIndex);
    }
    if (urlEndIndex != null && urlEndIndex != -1) {
      String imageUrl = html.substring(urlStartIndex, urlEndIndex);
      return "https://10.16.1.213/backend/$imageUrl";
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
        print('Clipboard is not available on this platform');
      }
    } else {
      print('Failed to read image');
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
}

//note for restore checkpoint