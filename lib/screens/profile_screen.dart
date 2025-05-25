// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
// import '../models/user_data_model.dart'; // Jika UserData model dari API berbeda

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

  // URL dasar untuk menampilkan gambar dari backend (sesuaikan jika berbeda)
  final String _baseImageUrl = "http://127.0.0.1:3000";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final result = await _userService.getUserProfile();
    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final userData = result['data'];
      setState(() {
        _userName = userData['name'];
        _userEmail = userData['email'];
        _userAddress = userData['address'];
        _userPhotoUrl = userData['photo_url'];
        _nameEditController.text = _userName ?? '';
        _isLoading = false;
      });
    } else {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal memuat profil.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Batasi ukuran gambar
        imageQuality: 70, // Kompresi gambar
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _uploadProfilePicture(); // Langsung unggah setelah dipilih
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;
    setState(() { _isUploading = true; });

    final result = await _userService.updateUserProfilePicture(_imageFile!);
    if (!mounted) return;

    setState(() { _isUploading = false; });
    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _userPhotoUrl = result['data']['filePath'];
         _imageFile = null; // Reset file setelah berhasil diunggah
      });
       // Perbarui juga di SharedPreferences agar AppDrawer update
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', result['data']?['user']?['name'] ?? _userName!); // Jika nama juga diupdate
      // await prefs.setString('userPhotoUrl', _userPhotoUrl!); // Simpan URL foto jika perlu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal unggah foto.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateUserName() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; }); // Bisa gunakan _isUploading atau state lain
      final newName = _nameEditController.text.trim();
      final result = await _userService.updateUserName(newName);
      if (!mounted) return;
      setState(() { _isLoading = false; _isEditingName = false; });

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _userName = result['data']['user']['name'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Nama berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal update nama.'), backgroundColor: Colors.red),
        );
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
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
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
          : RefreshIndicator(
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
                                ? NetworkImage(_baseImageUrl + _userPhotoUrl!) // Tambahkan base URL
                                : const AssetImage('assets/images/default_avatar.png')) as ImageProvider, // Sediakan default avatar
                         child: _isUploading ? const CircularProgressIndicator() : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => _showImageSourceActionSheet(context),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameEditController,
                            decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                            validator: (value) => (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
                          ),
                        ),
                        IconButton(icon: Icon(Icons.check, color: Colors.green), onPressed: _updateUserName),
                        IconButton(icon: Icon(Icons.close, color: Colors.red), onPressed: () => setState(()=> _isEditingName = false)),
                      ],
                    ),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_userName ?? 'Belum diatur'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _nameEditController.text = _userName ?? '';
                        setState(() => _isEditingName = true);
                      },
                    ),
                  ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_userEmail ?? 'Tidak ada email'),
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_userAddress ?? 'Belum diatur'),
                  // Tambahkan trailing IconButton jika ingin bisa edit alamat juga
                ),
                // Tambahkan field lain yang ingin ditampilkan/diedit
              ],
            ),
          ),
    );
  }
}