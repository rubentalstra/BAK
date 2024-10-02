import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/ui/widgets/full_screen_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bak_tracker/services/image_upload_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSavingProfile = false;
  bool _isUploadingImage = false;
  String? _profileImage;
  File? _localImageFile;

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final ImageUploadService _imageUploadService =
      ImageUploadService(Supabase.instance.client);

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

    setState(() {
      _isSavingProfile = true;
    });

    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      await _supabaseClient
          .from('users')
          .update({'name': displayName, 'bio': bio}).eq('id', userId);
      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      _showSnackBar('Error updating profile.');
    } finally {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? pickedImageFile = File(pickedFile.path);
      setState(() {
        _isUploadingImage = true;
      });

      await _uploadProfileImage(pickedImageFile);
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _uploadProfileImage(File pickedImageFile) async {
    final userId = _supabaseClient.auth.currentUser!.id;
    final hadPreviousImage = _profileImage != null;

    try {
      final newImageHashExtension =
          await _imageUploadService.uploadProfileImage(
        pickedImageFile,
        _profileImage,
      );

      if (newImageHashExtension != null) {
        await _supabaseClient
            .from('users')
            .update({'profile_image': newImageHashExtension}).eq('id', userId);

        setState(() {
          _profileImage = newImageHashExtension;
          _localImageFile = pickedImageFile;
        });
        _showSnackBar('Profile image updated successfully!');
      } else {
        _showSnackBar('Image already up-to-date or no upload needed.');
      }
    } catch (e) {
      _showSnackBar(
          'Error: ${e.toString().replaceAll('Exception:', '').trim()}');
      if (!hadPreviousImage) {
        setState(() {
          _localImageFile = null;
        });
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

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
      setState(() {
        _isUploadingImage = false;
      });
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
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _showFullScreenImage,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _localImageFile != null
                          ? FileImage(_localImageFile!)
                          : null,
                      child: _localImageFile == null
                          ? const Icon(Icons.person,
                              size: 80, color: Colors.grey)
                          : null,
                    ),
                  ),
                  if (_isUploadingImage)
                    const Positioned(child: CircularProgressIndicator()),
                  Positioned(
                    right: 10,
                    bottom: 0,
                    child: Container(
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
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Upload',
                            child: Row(
                              children: [
                                Icon(Icons.camera_alt,
                                    color: AppColors.lightSecondary),
                                SizedBox(width: 10),
                                Text('Upload Image'),
                              ],
                            ),
                          ),
                          if (_localImageFile != null)
                            const PopupMenuItem(
                              value: 'Delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.redAccent),
                                  SizedBox(width: 10),
                                  Text('Delete Image'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildProfileForm(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _displayNameController,
          label: 'Display Name',
          icon: Icons.person,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.info,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}
