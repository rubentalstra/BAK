import 'dart:io';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/services/pdf_upload_service.dart';
import 'package:bak_tracker/ui/widgets/pdf_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageRegulationsScreen extends StatefulWidget {
  const ManageRegulationsScreen({super.key});

  @override
  _ManageRegulationsScreenState createState() =>
      _ManageRegulationsScreenState();
}

class _ManageRegulationsScreenState extends State<ManageRegulationsScreen> {
  bool _isUploading = false; // Track the uploading state
  final PDFUploadService pdfService =
      PDFUploadService(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Regulations'),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoading || _isUploading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AssociationLoaded) {
            return _buildContent(state.selectedAssociation.bakRegulations,
                state.selectedAssociation.id);
          } else {
            return const Center(child: Text('Error loading association data.'));
          }
        },
      ),
    );
  }

  Widget _buildContent(String? bakRegulations, String associationId) {
    final hasRegulations = bakRegulations?.isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasRegulations) ...[
            _buildButton(
              icon: Icons.visibility,
              label: 'View Current Regulations',
              onPressed: () => _viewRegulations(bakRegulations!, associationId),
            ),
            _buildButton(
              icon: Icons.delete,
              label: 'Delete Regulations',
              onPressed: () =>
                  _confirmDeleteRegulations(bakRegulations!, associationId),
              color: Colors.red,
            ),
          ],
          _buildButton(
            icon: Icons.upload_file,
            label: hasRegulations ? 'Update Regulations' : 'Upload Regulations',
            onPressed: () => _uploadRegulations(associationId, bakRegulations),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
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

    setState(() => _isUploading = true); // Set uploading state

    try {
      await pdfService.uploadPdf(file, bakRegulations, associationId);
      _refreshAssociationModel();
      _showSnackBar('Regulations uploaded successfully.');
    } catch (e) {
      _showSnackBar('Failed to upload the PDF.', isError: true);
    } finally {
      setState(() => _isUploading = false); // Reset uploading state
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

  // Consolidated snack bar method
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
