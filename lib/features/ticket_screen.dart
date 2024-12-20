import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:fyp_scaneat_cc/models/ticket_info.dart';
import 'package:fyp_scaneat_cc/services/ticket_service.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({Key? key}) : super(key: key);

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final _ticketService = TicketService();
  bool _hasTicket = false;
  String _scannedCode = '';
  String _passengerName = '';
  String _travelDate = '';
  String _destination = '';
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _scanStatus = '';
  FlutterBarcodeSdk? _barcodeSdk;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeBarcodeSDK();
  }

  @override
  void dispose() {
    _barcodeSdk = null;
    super.dispose();
  }

  Future<void> _initializeBarcodeSDK() async {
    try {
      _barcodeSdk = FlutterBarcodeSdk();
      await _barcodeSdk?.init();
      
      // Set multiple barcode formats
      await _barcodeSdk?.setBarcodeFormats(
        0x02000000 | // PDF417
        0x00000001 | // CODE_39
        0x00000002 | // CODE_128
        0x00000004 | // CODE_93
        0x00000008   // CODABAR
      );

      // Configure runtime settings
      final runtimeSettings = {
        "ImageParameter": {
          "Name": "BarcodeReader_PDF417",
          "Description": "PDF417 barcode reading settings",
          "BarcodeFormatIds": ["BF_PDF417"],
          "DeblurLevel": 9,
          "ExpectedBarcodesCount": 1,
          "ScaleDownThreshold": 2300,
          "LocalizationModes": ["LM_CONNECTED_BLOCKS", "LM_SCAN_DIRECTLY", "LM_STATISTICS", "LM_LINES"],
          "GrayscaleTransformationModes": ["GTM_ORIGINAL", "GTM_INVERTED"]
        },
        "Version": "3.0"
      };

      await _barcodeSdk?.setParameters(jsonEncode(runtimeSettings));
      
      setState(() {
        _scanStatus = 'Scanner initialized successfully';
      });
    } catch (e) {
      setState(() {
        _scanStatus = 'Failed to initialize scanner: $e';
      });
      print('Error initializing barcode scanner: $e');
    }
  }

  void _parseTicketData(String barcodeText) {
    try {
      // Parse ticket information using TicketInfo model
      final ticketInfo = TicketInfo.fromBarcodeText(barcodeText);
      
      // Save ticket information to service
      _ticketService.setTicket(ticketInfo);

      setState(() {
        _passengerName = ticketInfo.passengerName;
        _travelDate = ticketInfo.travelDate.toString();
        _destination = ticketInfo.destination;
        _scannedCode = ''; // Do not display the original barcode text
        _scanStatus = 'Ticket successfully scanned and data stored.';
        _hasTicket = true;
      });

      print('Parsed Data - Name: ${ticketInfo.passengerName}, Date: ${ticketInfo.travelDate}, '
          'Destination: ${ticketInfo.destination}, Flight: ${ticketInfo.flightNumber}, '
          'Seat: ${ticketInfo.seatNumber}');
    } catch (e) {
      print('Error parsing ticket data: $e');
      setState(() {
        _scanStatus = 'Error occurred while parsing ticket data: $e';
      });
    }
  }

  Future<void> _scanImage(Uint8List bytes) async {
    try {
      if (_barcodeSdk == null) {
        await _initializeBarcodeSDK();
      }

      final ui.Image image = await decodeImageFromList(bytes);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba
      );
      
      if (byteData == null) {
        throw Exception('Failed to get image data');
      }

      print('Image size: ${image.width}x${image.height}');
      print('Bytes per row: ${byteData.lengthInBytes ~/ image.height}');

      final results = await _barcodeSdk!.decodeImageBuffer(
        byteData.buffer.asUint8List(),
        image.width,
        image.height,
        byteData.lengthInBytes ~/ image.height,
        ImagePixelFormat.IPF_ARGB_8888.index,
      );

      print('Scan results: ${results.length} barcodes found');
      for (var result in results) {
        print('Format: ${result.format}, Text: ${result.text}');
      }

      if (!mounted) return;
      if (results.isNotEmpty) {
        final scannedText = results.first.text;
        _parseTicketData(scannedText);
        setState(() {
          _scannedCode = scannedText;
          _hasTicket = true;
          _scanStatus = 'Ticket details extracted successfully!';
        });
      } else {
        setState(() {
          _scanStatus = 'No barcode found in image';
        });
      }
    } catch (e) {
      print('Error scanning image: $e');
      if (!mounted) return;
      setState(() {
        _scanStatus = 'Error scanning image: $e';
      });
    }
  }

  Future<void> _pickAndScanImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _scanStatus = 'Selecting image...';
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,  // Use maximum quality
        maxWidth: 1920,    // Increased max dimensions
        maxHeight: 1080,
      );
      
      if (image == null) {
        setState(() {
          _isProcessing = false;
          _scanStatus = 'No image selected';
        });
        return;
      }

      setState(() {
        _selectedImage = image;
        _scanStatus = 'Processing image...';
      });

      final bytes = await image.readAsBytes();
      await _scanImage(bytes);

    } catch (e) {
      print('Error picking image: $e');
      if (!mounted) return;
      setState(() {
        _scanStatus = 'Error picking image: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildImagePreview() {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasTicket) ...[
              // Success message card
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _scanStatus,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Ticket information card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_passengerName.isNotEmpty) ...[
                        const Text(
                          'Passenger Name:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _passengerName,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_travelDate.isNotEmpty) ...[
                        const Text(
                          'Travel Date:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _travelDate,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_destination.isNotEmpty) ...[
                        const Text(
                          'Destination:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _destination,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.qr_code_scanner,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'No Ticket Registered',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                _scanStatus,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickAndScanImage,
                icon: const Icon(Icons.image),
                label: const Text('Select Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 