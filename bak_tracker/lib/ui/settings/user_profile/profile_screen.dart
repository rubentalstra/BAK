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
  File? _profileImageFile;
  String? _profileImageUrl;
  String? _profileImagePath; // Store file path here

  // Initialize ImageUploadService
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

        // Fetch signed URL for profile image
        if (_profileImagePath != null) {
          _fetchProfileImage(_profileImagePath!);
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _fetchProfileImage(String filePath) async {
    final imageUrl = await _imageUploadService.getSignedUrl(filePath);
    if (imageUrl != null) {
      setState(() {
        _profileImageUrl = imageUrl;
      });
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
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImageFile == null) return;

    final userId = Supabase.instance.client.auth.currentUser!.id;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload the new profile image, passing the existing image's file path to delete it first
      final newFilePath = await _imageUploadService.uploadProfileImage(
        _profileImageFile!,
        userId,
        _profileImagePath, // Existing file path to be deleted
      );

      if (newFilePath != null) {
        // Update the profile image path in the database
        await Supabase.instance.client
            .from('users')
            .update({'profile_image_path': newFilePath}).eq('id', userId);

        // Fetch signed URL for the newly uploaded image
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
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProfileImage() async {
    if (_profileImagePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the ImageUploadService to delete the profile image
      await _imageUploadService.deleteProfileImage(_profileImagePath!);

      // Clear the profile image path in the database
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('users')
          .update({'profile_image_path': null}).eq('id', userId);

      setState(() {
        _profileImageUrl = null;
        _profileImagePath = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  _profileImageUrl != null
                      ? CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(_profileImageUrl!),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[800],
                          ),
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickProfileImage,
                      child: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 20,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_profileImageFile != null)
                ElevatedButton(
                  onPressed: _uploadProfileImage,
                  child: const Text('Upload Profile Image'),
                ),
              const SizedBox(height: 20),
              _buildInputField(
                context,
                controller: _displayNameController,
                label: 'Display Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                context,
                controller: _bioController,
                label: 'Bio',
                icon: Icons.edit,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateProfile,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              if (_profileImagePath != null)
                ElevatedButton.icon(
                  onPressed: _deleteProfileImage,
                  icon: const Icon(Icons.delete),
                  label: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : const Text('Delete Profile Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildInputField(BuildContext context,
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
