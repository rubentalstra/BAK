import 'dart:io';
import 'package:archive/archive_io.dart'; // Import archive_io for compression
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/ui/widgets/pdf_viewer_screen.dart';

class PDFUploadService {
  final SupabaseClient supabase;
  final Dio dio = Dio();

  PDFUploadService(this.supabase);

  static const int maxFileSizeInMB = 2; // Adjust as needed
  static const int maxFileSizeInBytes = maxFileSizeInMB * 1024 * 1024;
  static const Duration signedUrlCacheDuration = Duration(minutes: 30);

  // Get the local path to store PDFs
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Compute hash of the PDF file
  Future<String> _computePdfHash(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  // Compress the PDF using GZip
  Future<File> _compressPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final compressed = GZipEncoder().encode(bytes);
    final compressedFile = File('${pdfFile.path}.gz');
    await compressedFile.writeAsBytes(compressed!);
    return compressedFile;
  }

  // Decompress the GZip file to get the original PDF, save as a PDF locally
  Future<File> _decompressAndSaveAsPdf(
      File compressedFile, String fileHash) async {
    final compressedBytes = await compressedFile.readAsBytes();
    final decompressed = GZipDecoder().decodeBytes(compressedBytes);

    // Save as a PDF locally
    final pdfFilePath = '${await _getLocalPath()}/$fileHash.pdf';
    final pdfFile = File(pdfFilePath);
    await pdfFile.writeAsBytes(decompressed);

    return pdfFile;
  }

  // Check if the local decompressed PDF exists
  Future<File?> _getLocalDecompressedPdfIfExists(String pdfFileName) async {
    final fileHash = pdfFileName.split('.').first;
    final localPdfPath = '${await _getLocalPath()}/$fileHash.pdf';
    final localPdf = File(localPdfPath);

    // If local decompressed PDF exists, return it; otherwise, return null
    return (await localPdf.exists()) ? localPdf : null;
  }

  // Download and save PDF locally using hash.extension format
  Future<File?> _savePdfLocally(
      String signedUrl, String fileHash, String fileExtension) async {
    try {
      final gzFilePath =
          '${await _getLocalPath()}/$fileHash.$fileExtension.gz'; // Save compressed version
      final gzFile = File(gzFilePath);
      final response = await dio.download(signedUrl, gzFile.path);

      if (response.statusCode == 200) {
        // Decompress the downloaded GZ file and save the PDF
        return await _decompressAndSaveAsPdf(gzFile, fileHash);
      }
      throw Exception('Failed to download PDF from $signedUrl');
    } catch (e) {
      print('Failed to save PDF locally: $e');
      return null;
    }
  }

  Future<String?> uploadPdf(
      File pdfFile, String? existingPdf, String associationId) async {
    try {
      // Check if the file size exceeds the limit
      if (pdfFile.lengthSync() > maxFileSizeInBytes) {
        throw Exception('The file size exceeds the $maxFileSizeInMB MB limit.');
      }

      // Compress the PDF
      final compressedFile = await _compressPdf(pdfFile);

      // Compute the hash of the compressed file
      final newPdfHash = await _computePdfHash(compressedFile);
      final fileExt = 'pdf.gz'; // Compressed file has .gz extension
      final newFileName = '$newPdfHash.$fileExt';
      final newFilePath = '$associationId/$newFileName';

      // If there's an existing PDF, compare hash and delete the old PDF if necessary
      if (existingPdf != null && existingPdf.contains('.')) {
        final existingPdfHash = existingPdf.split('.').first;
        if (existingPdfHash == newPdfHash) {
          print('PDF hash matches, no need to upload.');
          return null; // No upload needed, the PDF is the same
        }

        // Delete the old PDF from Supabase
        await deletePdf(existingPdf, associationId);
      }

      // Upload the new compressed PDF to Supabase storage
      await supabase.storage
          .from('association-pdfs')
          .upload(newFilePath, compressedFile);

      // Update the associations table with the new PDF file name
      await supabase.from('associations').update(
              {'bak_regulations': newFileName}) // Update with the new file name
          .eq('id', associationId);

      // Return the new PDF file name if successful
      return newFileName;
    } catch (e) {
      print('Error uploading PDF: $e');

      // Throw a more specific message without the "Exception" prefix
      throw Exception(
          'Failed to upload PDF: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // Fetch or download a PDF, update it if needed
  Future<File?> fetchOrDownloadPdf(
      String pdfFileName, String associationId) async {
    if (!pdfFileName.contains('.')) {
      print('Invalid PDF file format');
      return null;
    }

    // Check if the local decompressed PDF exists
    final localPdf = await _getLocalDecompressedPdfIfExists(pdfFileName);
    if (localPdf != null) {
      // Return the local decompressed PDF if it exists
      return localPdf;
    }

    // Download and save the PDF if the decompressed version does not exist
    return await _downloadAndSavePdf(pdfFileName, associationId);
  }

  // Download PDF and save locally (compressed)
  Future<File?> _downloadAndSavePdf(
      String pdfFileName, String associationId) async {
    final fileHash = pdfFileName.split('.').first;
    final fileExtension = pdfFileName.split('.').last;
    final signedUrl = await _getSignedUrl(pdfFileName, associationId);

    if (signedUrl != null) {
      return await _savePdfLocally(signedUrl, fileHash,
          fileExtension); // Save compressed version and decompress
    } else {
      print('Failed to fetch signed URL for $pdfFileName');
      return null;
    }
  }

  // Generate signed URL for PDF
  Future<String?> _getSignedUrl(
      String pdfFileName, String associationId) async {
    try {
      final filePath = '$associationId/$pdfFileName';
      return await supabase.storage
          .from('association-pdfs')
          .createSignedUrl(filePath, signedUrlCacheDuration.inSeconds);
    } catch (e) {
      print('Error generating signed URL: $e');
      return null;
    }
  }

  Future<void> deletePdf(String pdfFileName, String associationId) async {
    if (!pdfFileName.contains('.')) {
      print('Invalid PDF file format');
      return;
    }

    final fileHash = pdfFileName.split('.').first;
    final fileExtension = 'pdf.gz'; // Ensure the correct file extension
    final fileName =
        '$fileHash.$fileExtension'; // Correct the file extension to .pdf.gz
    final filePath = '$associationId/$fileName';

    try {
      // Delete the file from Supabase storage
      await supabase.storage.from('association-pdfs').remove([filePath]);

      // Delete the compressed PDF locally
      final localGzPath = '${await _getLocalPath()}/$fileHash.$fileExtension';
      final localGzFile = File(localGzPath);
      if (await localGzFile.exists()) {
        await localGzFile.delete();
        print('Deleted local compressed PDF: $localGzPath');
      }

      // Also delete the decompressed local PDF
      final localPdfPath = '${await _getLocalPath()}/$fileHash.pdf';
      final localPdfFile = File(localPdfPath);
      if (await localPdfFile.exists()) {
        await localPdfFile.delete();
        print('Deleted local decompressed PDF: $localPdfPath');
      }

      // Update the associations table to remove the bak_regulations field
      await supabase
          .from('associations')
          .update({'bak_regulations': null}) // Set bak_regulations to null
          .eq('id', associationId);

      print('Bak regulations removed from the association.');
    } catch (e) {
      print('Error during PDF deletion: $e');

      // Throw a more specific message without the "Exception" prefix
      throw Exception(
          'Failed to Delete PDF: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // Read the PDF locally (e.g., open it in a PDF viewer)
  Future<void> openPdf(BuildContext context, File pdfFile) async {
    // Navigate to the PDF viewer screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(pdfFilePath: pdfFile.path),
      ),
    );
  }
}
