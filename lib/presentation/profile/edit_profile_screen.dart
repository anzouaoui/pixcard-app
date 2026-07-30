import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      _pseudoController.text = user.displayName;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = user.photoUrl;

      if (_selectedImage != null) {
        final storage = ref.read(firebaseStorageProvider);
        final storageRef = storage.ref('profile_photos/${user.id}.jpg');
        await storageRef.putFile(_selectedImage!);
        photoUrl = await storageRef.getDownloadURL();
      }

      final updatedUser = AppUser(
        id: user.id,
        email: user.email,
        displayName: _pseudoController.text.trim(),
        photoUrl: photoUrl,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        createdAt: user.createdAt,
        salesCount: user.salesCount,
        rating: user.rating,
        reliabilityScore: user.reliabilityScore,
      );

      await ref.read(userRepositoryProvider).updateUser(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? NetworkImage(user.photoUrl!)
                              : null),
                      child: _selectedImage == null &&
                              (user.photoUrl == null || user.photoUrl!.isEmpty)
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.headlineLarge,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _pseudoController,
                decoration: const InputDecoration(labelText: 'Pseudo'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Le pseudo est requis';
                  }
                  if (v.trim().length < 3) {
                    return 'Minimum 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
