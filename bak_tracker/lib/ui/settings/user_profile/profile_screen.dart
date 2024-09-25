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
  bool _isLoading = false;
  String? _profileImagePath;
  bool _isUploadingImage = false;
  File? _localImageFile;

  final ImageUploadService _imageUploadService =
      ImageUploadService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name, profile_image_path, bio')
          .eq('id', userId)
          .single();

      if (response.isNotEmpty) {
        setState(() {
          _displayNameController.text = response['name'];
          _bioController.text = response['bio'] ?? '';
          _profileImagePath = response['profile_image_path'];
        });

        if (_profileImagePath != null) {
          _fetchProfileImage(_profileImagePath!);
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _fetchProfileImage(String filePath) async {
    if (filePath.isEmpty) {
      setState(() {
        _localImageFile = null;
      });
      return;
    }

    final localImage = await _imageUploadService.getLocalImage(filePath);
    if (localImage != null) {
      setState(() {
        _localImageFile = localImage;
      });
    } else {
      final imageUrl =
          await _imageUploadService.fetchOrDownloadProfileImage(filePath);
      if (imageUrl != null) {
        setState(() {
          _localImageFile = imageUrl;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();
    final userId = Supabase.instance.client.auth.currentUser!.id;

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.from('users').update({
        'name': displayName,
        'bio': bio,
      }).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _localImageFile = File(pickedFile.path);
        _isUploadingImage = true;
      });
      _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_localImageFile == null) return;

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final newFilePath = await _imageUploadService.uploadProfileImage(
        _localImageFile!,
        userId,
        _profileImagePath,
      );

      if (newFilePath != null) {
        await Supabase.instance.client
            .from('users')
            .update({'profile_image_path': newFilePath}).eq('id', userId);

        // Fetch and display the new image
        _fetchProfileImage(newFilePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading profile image.')),
        );
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _deleteProfileImage() async {
    if (_profileImagePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _imageUploadService.deleteProfileImage(_profileImagePath!);

      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('users')
          .update({'profile_image_path': null}).eq('id', userId);

      setState(() {
        _profileImagePath = null; // Clear the image path
        _localImageFile = null; // Clear the local image file
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting profile image: $e');
    } finally {
      setState(() {
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
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
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  if (_isUploadingImage)
                    const Positioned(
                      child: CircularProgressIndicator(),
                    ),
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
                          switch (value) {
                            case 'Upload':
                              _pickProfileImage();
                              break;
                            case 'Delete':
                              _deleteProfileImage();
                              break;
                          }
                        },
                        icon: const Icon(
                          Icons.more_vert,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Upload',
                            child: Row(
                              children: [
                                Icon(Icons.camera_alt,
                                    color: AppColors.lightSecondary),
                                SizedBox(width: 10),
                                Text('Upload Image',
                                    style: TextStyle(
                                        color: AppColors.lightOnPrimary)),
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
                                  Text('Delete Image',
                                      style: TextStyle(
                                          color: AppColors.lightOnPrimary)),
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
                onPressed: _isLoading ? null : _updateProfile,
                icon: _isLoading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
