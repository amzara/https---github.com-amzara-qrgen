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
      theme: ThemeData.dark(),
      home: mergeSingle(),
    );
  }
}

class mergeSingle extends StatefulWidget {
  @override
  _MergeSingleState createState() => _MergeSingleState();
}

class _MergeSingleState extends State<mergeSingle> {
  TextEditingController extController = TextEditingController();
  TextEditingController domainController = TextEditingController();
  String apiResponse = '';
  String? extractedImgUrl;

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.dark(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Generate Single QR Code'),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: extController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(labelText: 'Extension'),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: domainController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(labelText: 'Domain'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      fetchData(); // Call the method to fetch data from API
                    },
                    child: Text('Generate QR Code'),
                  ),
                  SizedBox(height: 20),
                  if (extractedImgUrl != null) ...[
                    Text(
                      'QR code for extension:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      extController.text,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(width: 15),
                    SizedBox(height: 20),
                    Image.network(
                      extractedImgUrl!, // Use extractedImgUrl as the image URL
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            copyToClipboard(); // Call the method to copy image to clipboard
                          },
                          child: Icon(Icons.content_copy),
                        ),
                        SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: () {
                            exportAsPDF(); // Call the method to export as PDF
                          },
                          child: Icon(Icons.picture_as_pdf),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final bytes =
                                await _readImageBytes(extractedImgUrl!);
                            if (bytes != null) {
                              await _saveImageToGallery(bytes);
                            }
                          },
                          child: Icon(Icons.file_download),
                        )
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> fetchData() async {
    String ext = extController.text;
    String domain = domainController.text;

    // Construct the URL with ext and domain entered by the user
    String url = 'https://10.16.1.213/backend/crp2.php?ext=$ext&domain=$domain';

    // Perform GET request
    var response = await http.get(Uri.parse(url));
    setState(() {
      // Set the response text to apiResponse variable
      apiResponse = response.body;

      // Extract img URL from the response
      var tempUrl = newCustomFunction(apiResponse);
      if (tempUrl != null) {
        extractedImgUrl = tempUrl;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR not found for extension $ext'),
            duration: Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  Future<void> exportAsPDF() async {
    try {
      if (extractedImgUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generating PDF...'),
            duration: Duration(milliseconds: 500),
          ),
        );
        // Generate PDF if extractedImgUrl is not null
        await generatePdf(extractedImgUrl!);
      } else {
        print('No image URL available to export as PDF.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image URL available to export as PDF.')),
        );
      }
    } catch (e) {
      print('Error exporting as PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting as PDF: $e')),
      );
    }
  }

  Future<void> copyToClipboard() async {
    try {
      if (extractedImgUrl != null) {
        // Copy image to clipboard if extractedImgUrl is not null
        await copyImageToClipboard(extractedImgUrl!);
      } else {
        print('No image URL available to copy.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image URL available to copy.')),
        );
      }
    } catch (e) {
      print('Error copying to clipboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error copying to clipboard: $e')),
      );
    }
  }

  String? newCustomFunction(String? html) {
    /// MODIFY CODE ONLY BELOW THIS LINE

    // Find the index of 'src' attribute
    int? srcIndex = html!.indexOf('src=');

    // If 'src' attribute is found
    if (srcIndex != null && srcIndex != -1) {
      // Move the index to the start of the URL
      int urlStartIndex = srcIndex + 5; // 5 is the length of 'src='

      // Find the closing quote of the URL
      int? urlEndIndex = html.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html.indexOf('"', urlStartIndex);
      }

      // Extract the URL if urlEndIndex is not null
      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        // Append the base URL
        return "https://10.16.1.213/backend/$imageUrl";
      }
    }

    // If 'src' attribute is not found or URL extraction fails, return null

    return null;

    /// MODIFY CODE ONLY ABOVE THIS LINE
  }

  Future<void> generatePdf(String imageUrl) async {
    try {
      // Create a new PDF document
      PdfDocument document = PdfDocument();

      // Load image data into PDF bitmap object
      var response = await http.get(Uri.parse(imageUrl));
      var data = response.bodyBytes;
      PdfBitmap image = PdfBitmap(data);

      // Get the dimensions of the image
      double imageWidth = 500;
      double imageHeight = 500;

      // Draw image on the page graphics, setting width and height dynamically
      // Create a new page
      PdfPage page = document.pages.add();

      // Draw the image on the page
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 50, imageWidth, imageHeight),
      );

      // Draw the string on the same page
      page.graphics.drawString(
        'QR Code for Extension ${extController.text}',
        PdfStandardFont(PdfFontFamily.helvetica, 20),
        bounds: Rect.fromLTWH(
          120, // Change the x-coordinate to 0 to place the text label next to the image
          0, // Change the y-coordinate to maxHeight to place the text label below the image
          300,
          500,
        ),
      );

      // Save the document
      final List<int> bytes = await document.save(); // Await here
      // Dispose the document
      document.dispose();

      // Get the directory for saving PDF
      final directory = await getTemporaryDirectory();
      final String tempPath = directory.path;

      // Generate a unique file name based on current date and time
      final String fileName =
          DateFormat('yyyyMMddHHmmss').format(DateTime.now());

      // Write PDF bytes to a temporary file
      final tempFile = File('$tempPath/$fileName.pdf');
      await tempFile.writeAsBytes(bytes, flush: true);

      // Get permission to access the downloads directory
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Move the file to the downloads directory
      final downloadsDirectory = await getDownloadsDirectory();
      final String downloadsPath = downloadsDirectory!.path;
      final String newPath = '$downloadsPath/$fileName.pdf';
      await tempFile.copy(newPath);

      print('PDF generated successfully at: $newPath');

      // Open the PDF file
      OpenFile.open(newPath);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  Future<void> copyImageToClipboard(String imageUrl) async {
    final bytes = await _readImageBytes(imageUrl);
    if (bytes != null) {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem(suggestedName: 'Image.png');
        item.add(Formats.png(bytes));
        await clipboard.write([item]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image copied to clipboard')),
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
      // Perform a GET request to fetch the image data
      final response = await http.get(Uri.parse(imageUrl));

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Convert the response body (image data) to bytes
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