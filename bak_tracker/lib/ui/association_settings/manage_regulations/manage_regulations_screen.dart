import 'dart:io';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/services/pdf_upload_service.dart';
import 'package:bak_tracker/ui/widgets/pdf_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/core/themes/colors.dart'; // Import AppColors

class ManageRegulationsScreen extends StatefulWidget {
  const ManageRegulationsScreen({super.key});

  @override
  _ManageRegulationsScreenState createState() =>
      _ManageRegulationsScreenState();
}

class _ManageRegulationsScreenState extends State<ManageRegulationsScreen> {
  bool _isUploading = false;
  final PDFUploadService pdfService =
      PDFUploadService(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Regulations'),
        backgroundColor: AppColors.lightPrimary,
        centerTitle: true,
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoading || _isUploading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AssociationLoaded) {
            return _buildContent(
                state.selectedAssociation.bakRegulations,
                state.selectedAssociation.id,
                state.selectedAssociation.updatedAt
                    .toLocal()); // Convert to local time
          } else {
            return const Center(child: Text('Error loading association data.'));
          }
        },
      ),
    );
  }

  Widget _buildContent(
      String? bakRegulations, String associationId, DateTime? updatedAt) {
    final hasRegulations = bakRegulations?.isNotEmpty ?? false;

    // Format the last updated time in local time zone
    final lastUpdated = updatedAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(updatedAt)
        : 'Not available';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(hasRegulations, lastUpdated),
          const SizedBox(height: 16),
          if (hasRegulations) ...[
            _buildActionButton(
              icon: Icons.visibility,
              label: 'View Current Regulations',
              onPressed: () => _viewRegulations(bakRegulations!, associationId),
            ),
            _buildActionButton(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Regulations',
              onPressed: () =>
                  _confirmDeleteRegulations(bakRegulations!, associationId),
              color: Colors.redAccent,
            ),
          ],
          _buildActionButton(
            icon: Icons.upload_file,
            label: hasRegulations ? 'Update Regulations' : 'Upload Regulations',
            onPressed: () => _uploadRegulations(associationId, bakRegulations),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool hasRegulations, String lastUpdated) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBackground, // Updated to dark card background
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.file_copy_rounded,
              size: 50,
              color: AppColors.lightSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasRegulations
                        ? 'Regulations Uploaded'
                        : 'No Regulations Uploaded',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightOnPrimary, // Light text color
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: $lastUpdated',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightDivider, // Lighter text for details
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: AppColors.lightOnPrimary), // Updated icon color
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.lightOnPrimary), // Text color updated
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              color ?? AppColors.lightSecondary, // Use app color scheme
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _viewRegulations(
      String bakRegulations, String associationId) async {
    try {
      final pdfFile =
          await pdfService.fetchOrDownloadPdf(bakRegulations, associationId);
      if (pdfFile != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(pdfFilePath: pdfFile.path),
          ),
        );
      } else {
        _showSnackBar('Failed to retrieve the PDF.', isError: true);
      }
    } catch (e) {
      _showSnackBar('An error occurred while opening the PDF.', isError: true);
    }
  }

  Future<void> _uploadRegulations(
      String associationId, String? bakRegulations) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);

    setState(() => _isUploading = true);

    try {
      await pdfService.uploadPdf(file, bakRegulations, associationId);
      _refreshAssociationModel();
      _showSnackBar('Regulations uploaded successfully.');
    } catch (e) {
      _showSnackBar('Failed to upload the PDF.', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteRegulations(
      String bakRegulations, String associationId) async {
    try {
      await pdfService.deletePdf(bakRegulations, associationId);
      _refreshAssociationModel();
      _showSnackBar('Regulations deleted successfully.');
    } catch (e) {
      _showSnackBar('Failed to delete the PDF.', isError: true);
    }
  }

  void _confirmDeleteRegulations(String bakRegulations, String associationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Regulations'),
          content: const Text(
              'Are you sure you want to delete the current regulations? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRegulations(bakRegulations, associationId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _refreshAssociationModel() {
    final associationBloc = context.read<AssociationBloc>();
    associationBloc.add(SelectAssociation(
      selectedAssociation:
          (associationBloc.state as AssociationLoaded).selectedAssociation,
    ));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
