import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/widgets/full_screen_profile_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final ImageUploadService _imageUploadService =
      ImageUploadService(Supabase.instance.client);

  // Max character limits
  final int _maxNameLength = 255;
  final int _maxBioLength = 510;

  bool _isSavingProfile = false;
  bool _isUploadingImage = false;
  String? _profileImage;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      final response = await _supabaseClient
          .from('users')
          .select('name, profile_image, bio')
          .eq('id', userId)
          .single();

      if (response.isNotEmpty) {
        _displayNameController.text = response['name'];
        _bioController.text = response['bio'] ?? '';
        _profileImage = response['profile_image'];

        if (_profileImage != null) {
          final localImage = await _imageUploadService
              .fetchOrDownloadProfileImage(_profileImage!);
          setState(() {
            _localImageFile = localImage;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e');
    }
  }

  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();

    if (displayName.isEmpty) {
      _showSnackBar('Display name cannot be empty.');
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      await _supabaseClient
          .from('users')
          .update({'name': displayName, 'bio': bio}).eq('id', userId);
      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      String errorMessage = 'Error updating profile.';
      if (e is PostgrestException) {
        errorMessage = _handlePostgrestException(e);
      }
      _showSnackBar(errorMessage);
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  String _handlePostgrestException(PostgrestException e) {
    if (e.code == '23514') {
      if (e.message.contains('namechk')) {
        return 'Display name does not meet the required criteria. Please ensure it follows the naming rules.';
      } else if (e.message.contains('biochk')) {
        return 'Bio does not meet the required criteria. Please ensure your bio adheres to the allowed character limits.';
      }
    }
    return 'Error updating profile.';
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);

      await _uploadProfileImage(File(pickedFile.path));
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _uploadProfileImage(File pickedImageFile) async {
    final userId = _supabaseClient.auth.currentUser!.id;

    try {
      final newImageHash = await _imageUploadService.uploadProfileImage(
        pickedImageFile,
        _profileImage,
      );

      if (newImageHash != null) {
        await _supabaseClient
            .from('users')
            .update({'profile_image': newImageHash}).eq('id', userId);
        setState(() {
          _profileImage = newImageHash;
          _localImageFile = pickedImageFile;
        });
        _showSnackBar('Profile image updated successfully!');
      } else {
        _showSnackBar('Image already up-to-date.');
      }
    } catch (e) {
      _showSnackBar('Error uploading profile image.');
    }
  }

  Future<void> _deleteProfileImage() async {
    if (_profileImage == null) return;

    setState(() => _isUploadingImage = true);

    try {
      await _imageUploadService.deleteProfileImage(_profileImage!);

      final userId = _supabaseClient.auth.currentUser!.id;
      await _supabaseClient
          .from('users')
          .update({'profile_image': null}).eq('id', userId);

      setState(() {
        _profileImage = null;
        _localImageFile = null;
      });
      _showSnackBar('Profile image deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting profile image.');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showFullScreenImage() {
    if (_localImageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FullScreenImage(localImageFile: _localImageFile!),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildProfileImageSection(),
              const SizedBox(height: 30),
              _buildProfileForm(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _showFullScreenImage,
          child: CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                _localImageFile != null ? FileImage(_localImageFile!) : null,
            child: _localImageFile == null
                ? const Icon(Icons.person, size: 80, color: Colors.grey)
                : null,
          ),
        ),
        if (_isUploadingImage) const CircularProgressIndicator(),
        Positioned(
          right: 10,
          bottom: 0,
          child: _buildImageOptionsButton(),
        ),
      ],
    );
  }

  Widget _buildImageOptionsButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'Upload') {
            _pickProfileImage();
          } else if (value == 'Delete') {
            _deleteProfileImage();
          }
        },
        icon: const Icon(Icons.more_vert, color: AppColors.lightSecondary),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'Upload',
            child: ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.lightSecondary),
              title: Text('Upload Image'),
            ),
          ),
          if (_localImageFile != null)
            const PopupMenuItem(
              value: 'Delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.redAccent),
                title: Text('Delete Image'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        _buildStyledInputField(
          controller: _displayNameController,
          label: 'Display Name',
          icon: Icons.person,
          maxLength: _maxNameLength,
        ),
        const SizedBox(height: 20),
        _buildStyledInputField(
          controller: _bioController,
          label: 'Bio',
          maxLines: 12,
          maxLength: _maxBioLength,
        ),
      ],
    );
  }

  Widget _buildStyledInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              maxLength: maxLength,
              decoration: InputDecoration(
                icon: icon != null ? Icon(icon, color: Colors.blue) : null,
                border: InputBorder.none,
                counterText: '${controller.text.length} / $maxLength',
                counterStyle: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSavingProfile ? null : _updateProfile,
      icon: _isSavingProfile
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save),
      label: const Text('Save Changes'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: AppColors.lightPrimary,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
