import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfFilePath;

  const PDFViewerScreen({super.key, required this.pdfFilePath});

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PdfController _pdfController;
  int _currentPage = 0;
  int? _totalPages;

  @override
  void initState() {
    super.initState();
    // Load the PDF from file path
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfFilePath),
      initialPage: 1, // Set the initial page
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
          if (_totalPages != null)
            Center(
              child: Text(
                '${_currentPage + 1}/$_totalPages',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: PdfView(
        controller: _pdfController,
        onPageChanged: (int? page) {
          setState(() {
            _currentPage = page ?? 0;
          });
        },
        onDocumentLoaded: (document) {
          setState(() {
            _totalPages = document.pagesCount;
          });
        },
      ),
    );
  }
}
