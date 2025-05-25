// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  final _nameEditController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _userName;
  String? _userEmail;
  String? _userAddress;
  String? _userPhotoUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isEditingName = false;
  String? _errorMessage; // <-- DEKLARASIKAN _errorMessage DI SINI

  // URL dasar untuk menampilkan gambar dari backend
  // Gunakan 10.0.2.2 untuk Android Emulator jika backend di localhost komputer Anda
  final String _baseImageUrl = "http://10.0.2.2:3000"; // <-- PERBAIKI INI JIKA PERLU

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameEditController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset pesan error setiap kali load
    });

    final result = await _userService.getUserProfile();
    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final userData = result['data'];
      try {
        setState(() {
          _userName = userData['name'];
          _userEmail = userData['email'];
          _userAddress = userData['address'];
          _userPhotoUrl = userData['photo_url'];
          _nameEditController.text = _userName ?? '';
          _isLoading = false;
        });
      } catch (e) {
        print("Error setting state in _loadUserProfile: $e");
        setState(() {
          _errorMessage = "Gagal memproses data profil.";
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat profil.';
        _isLoading = false;
      });
      // SnackBar bisa tetap ada atau dihilangkan jika sudah ada tampilan error di body
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      // );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;
    if (!mounted) return;
    setState(() { _isUploading = true; });

    final result = await _userService.updateUserProfilePicture(_imageFile!);
    if (!mounted) return;

    setState(() { _isUploading = false; });
    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _userPhotoUrl = result['data']['filePath'];
        _imageFile = null;
      });
      // Perbarui juga photoUrl di SharedPreferences jika AppDrawer menggunakannya
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // if (_userPhotoUrl != null) {
      //   await prefs.setString('userPhotoUrl', _userPhotoUrl!);
      // }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal unggah foto.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateUserName() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() { _isUploading = true; _isEditingName = false; }); // Gunakan _isUploading untuk loading

      final newName = _nameEditController.text.trim();
      final result = await _userService.updateUserName(newName);
      if (!mounted) return;

      setState(() { _isUploading = false; });

      if (result['success'] == true && result['data'] != null) {
        final updatedUserName = result['data']['user']['name'];
        setState(() {
          _userName = updatedUserName;
        });
        // Update nama di SharedPreferences agar AppDrawer juga update
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', updatedUserName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Nama berhasil diperbarui!'), backgroundColor: Colors.green),
          );
        }
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal update nama.'), backgroundColor: Colors.red),
          );
         }
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeri Foto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _userName == null // Tampilkan error jika data profil utama gagal dimuat
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _loadUserProfile, child: const Text('Coba Lagi'))
                      ],
                    ),
                  ))
              : RefreshIndicator( // RefreshIndicator tetap ada untuk data yang sudah ada
                  onRefresh: _loadUserProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                      ? NetworkImage(_baseImageUrl + _userPhotoUrl!)
                                      : const AssetImage('assets/images/default_avatar.png')) as ImageProvider,
                              child: _isUploading ? const CircularProgressIndicator() : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _isUploading ? null : () => _showImageSourceActionSheet(context), // Nonaktifkan saat uploading
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: _isUploading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                      : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isEditingName)
                        Form(
                          key: _formKey,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nameEditController,
                                  decoration: const InputDecoration(labelText: 'Nama Lengkap', isDense: true),
                                  validator: (value) => (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
                                ),
                              ),
                              IconButton(icon: Icon(Icons.check, color: Colors.green[700]), onPressed: _isUploading ? null : _updateUserName),
                              IconButton(icon: Icon(Icons.close, color: Colors.red[700]), onPressed: _isUploading ? null : () => setState(()=> _isEditingName = false)),
                            ],
                          ),
                        )
                      else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                          subtitle: Text(_userName ?? 'Belum diatur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                            onPressed: _isUploading ? null : () {
                              _nameEditController.text = _userName ?? '';
                              setState(() => _isEditingName = true);
                            },
                          ),
                        ),
                      const Divider(height: 30),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                        subtitle: Text(_userEmail ?? 'Tidak ada email', style: const TextStyle(fontSize: 16)),
                      ),
                      const Divider(height: 30),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                        subtitle: Text(_userAddress ?? 'Belum diatur', style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
    );
  }
}