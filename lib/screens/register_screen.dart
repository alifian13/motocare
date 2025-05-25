// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
// import '../services/location_service.dart'; // LocationService tidak digunakan di registrasi API saat ini

// Model data sederhana untuk dropdown, bisa dipisah ke file model jika kompleks
class DropdownOption {
  final String id; // e.g., 'honda', 'beat'
  final String name; // e.g., 'Honda', 'Beat'
  DropdownOption(this.id, this.name);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedBrandId; // Ini akan menyimpan nilai seperti 'honda'
  String? _selectedModelId; // Ini akan menyimpan nilai seperti 'beat'
  DateTime? _selectedServiceDate;

  // final LocationService _locationService = LocationService(); // Tidak digunakan di sini
  final UserService _userService = UserService();
  bool _isLoading = false;

  // Data dropdown (sesuaikan dengan kebutuhan)
  final List<DropdownOption> _brands = [
    DropdownOption('Honda', 'Honda'), // ID bisa sama dengan nama jika sederhana
    DropdownOption('Yamaha', 'Yamaha'),
    DropdownOption('Suzuki', 'Suzuki'),
    DropdownOption('Kawasaki', 'Kawasaki'),
  ];

  final Map<String, List<DropdownOption>> _models = {
    'Honda': [ DropdownOption('Beat', 'Beat'), DropdownOption('Vario', 'Vario'), DropdownOption('PCX', 'PCX') ],
    'Yamaha': [ DropdownOption('NMAX', 'NMAX'), DropdownOption('Aerox', 'Aerox'), DropdownOption('Mio', 'Mio') ],
    'Suzuki': [ DropdownOption('Address', 'Address'), DropdownOption('NEX II', 'NEX II') ],
    'Kawasaki': [ DropdownOption('Ninja 250', 'Ninja 250'), DropdownOption('KLX 150', 'KLX 150') ],
  };
  List<DropdownOption> _currentModels = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedServiceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedServiceDate) {
      setState(() {
        _selectedServiceDate = picked;
      });
    }
  }

  Future<void> _attemptRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Dapatkan nama brand dan model berdasarkan ID yang dipilih
      String brandName = _brands.firstWhere((b) => b.id == _selectedBrandId, orElse: () => DropdownOption('', '')).name;
      String modelName = _currentModels.firstWhere((m) => m.id == _selectedModelId, orElse: () => DropdownOption('', '')).name;


      final result = await _userService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        address: _addressController.text.trim(),
        plateNumber: _plateController.text.trim().toUpperCase(),
        brand: brandName, // Kirim nama brand
        motorModel: modelName, // Kirim nama model
        currentOdometer: int.tryParse(_odometerController.text.trim()),
        lastServiceDate: _selectedServiceDate,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']?['message'] ?? 'Pendaftaran berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login'); // Arahkan ke login setelah registrasi
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pendaftaran gagal. Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi MotoCare'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (TextFormField Anda yang sudah ada, pastikan controller dan validator sesuai)
              // Contoh untuk Nama Lengkap:
              _buildTextField(controller: _nameController, label: 'Nama Lengkap', hint: 'Masukkan nama lengkap Anda'),
              const SizedBox(height: 15),
              _buildTextField(controller: _emailController, label: 'Email', hint: 'contoh@email.com', keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                  if (!value.contains('@') || !value.contains('.')) return 'Format email tidak valid';
                  return null;
                }
              ),
              const SizedBox(height: 15),
              _buildTextField(controller: _passwordController, label: 'Password', hint: 'Minimal 6 karakter', obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                  if (value.length < 6) return 'Password minimal 6 karakter';
                  return null;
                }
              ),
              const SizedBox(height: 15),
              _buildTextField(controller: _addressController, label: 'Alamat', hint: 'Masukkan alamat Anda', maxLines: 2),
              const SizedBox(height: 15),
              const Divider(thickness: 1, height: 30),
              Text("Informasi Kendaraan Utama", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildTextField(controller: _plateController, label: 'Plat Nomor', hint: 'AB 1234 CD',
                validator: (value) => (value == null || value.isEmpty) ? 'Plat Nomor tidak boleh kosong' : null
              ),
              const SizedBox(height: 15),
              _buildDropdownField(
                label: 'Brand Kendaraan',
                hint: 'Pilih Brand',
                value: _selectedBrandId,
                items: _brands,
                onChanged: (value) {
                  setState(() {
                    _selectedBrandId = value;
                    _selectedModelId = null; // Reset model
                    _currentModels = _models[_selectedBrandId ?? ''] ?? [];
                  });
                },
                validator: (value) => (value == null) ? 'Brand wajib dipilih' : null
              ),
              const SizedBox(height: 15),
              if (_selectedBrandId != null && _currentModels.isNotEmpty)
                _buildDropdownField(
                  label: 'Model Kendaraan',
                  hint: 'Pilih Model',
                  value: _selectedModelId,
                  items: _currentModels,
                  onChanged: (value) {
                    setState(() {
                      _selectedModelId = value;
                    });
                  },
                  validator: (value) => (value == null) ? 'Model wajib dipilih' : null
                ),
              if (_selectedBrandId != null && _currentModels.isNotEmpty) const SizedBox(height: 15),
              _buildTextField(controller: _odometerController, label: 'Odometer Saat Ini (km)', hint: 'Contoh: 15000', keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                    return 'Odometer harus angka';
                  }
                  return null; // Odometer bisa jadi opsional atau default 0
                }
              ),
              const SizedBox(height: 15),
              _buildDateField(context), // Tanggal terakhir servis
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _attemptRegister,
                      child: const Text('DAFTAR'),
                    ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Sudah punya akun? Login di sini'),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets (_buildTextField, _buildDateField, _buildDropdownField)
  // Pastikan helper widget ini ada di dalam class _RegisterScreenState atau bisa diakses
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField( // Menggunakan TextFormField untuk integrasi dengan Form
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          // Beberapa field mungkin opsional, tangani di validator spesifik
          // return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal Terakhir Servis (Opsional)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  _selectedServiceDate == null
                      ? 'Pilih Tanggal'
                      : "${_selectedServiceDate!.day}/${_selectedServiceDate!.month}/${_selectedServiceDate!.year}",
                  style: TextStyle(color: _selectedServiceDate == null ? Colors.grey[600] : Colors.black87),
                ),
                Icon(Icons.calendar_today, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

   Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value, // Ini adalah ID dari DropdownOption
    required List<DropdownOption> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: value,
      isExpanded: true,
      items: items.map((DropdownOption item) {
        return DropdownMenuItem<String>(
          value: item.id, // Simpan ID
          child: Text(item.name), // Tampilkan Nama
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}