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
  String? _profileImage;
  File? _localImageFile;
  // Placeholder for ImageUploadService and other logic
  bool _isUploadingImage = false;

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final ImageUploadService _imageUploadService =
      ImageUploadService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _supabaseClient.auth.currentUser!.id;
    try {
      // Fetch user profile data from Supabase
      final response = await _supabaseClient
          .from('users')
          .select('name, profile_image, bio')
          .eq('id', userId)
          .single();

      if (response.isNotEmpty) {
        // Update controllers with the fetched data
        _displayNameController.text = response['name'];
        _bioController.text = response['bio'] ?? '';
        _profileImage = response['profile_image'];

        // Check if profile image exists
        if (_profileImage != null) {
          // Fetch or download the profile image
          final localImage = await _imageUploadService
              .fetchOrDownloadProfileImage(_profileImage!);

          // Update state with the local image file if it was successfully fetched
          if (localImage != null) {
            setState(() {
              _localImageFile = localImage;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _fetchProfileImage(String filePath) async {
    try {
      final imageUrl =
          await _imageUploadService.fetchOrDownloadProfileImage(filePath);
      if (imageUrl != null) {
        setState(() {
          _localImageFile = imageUrl;
        });
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();
    final userId = _supabaseClient.auth.currentUser!.id;

    if (displayName.isEmpty) {
      _showSnackBar('Display name cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseClient
          .from('users')
          .update({'name': displayName, 'bio': bio}).eq('id', userId);

      _showSnackBar('Profile updated successfully!');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error updating profile: $e');
      _showSnackBar('Error updating profile.');
      setState(() {
        _isLoading = false;
      });
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
        _isLoading = true;
      });
      _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_localImageFile == null) return;

    final userId = _supabaseClient.auth.currentUser!.id;

    try {
      final newImageHashExtension =
          await _imageUploadService.uploadProfileImage(
        _localImageFile!,
        _profileImage,
      );

      if (newImageHashExtension != null) {
        await _supabaseClient
            .from('users')
            .update({'profile_image': newImageHashExtension}).eq('id', userId);

        setState(() {
          _profileImage = newImageHashExtension;
        });

        await _fetchProfileImage(newImageHashExtension);

        _showSnackBar('Profile image updated successfully!');
      } else {
        _showSnackBar('Image already up-to-date.');
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
    if (_profileImage == null) return;

    setState(() {
      _isLoading = true;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                onPressed: _isLoading ? null : _updateProfile,
                icon: _isLoading
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
