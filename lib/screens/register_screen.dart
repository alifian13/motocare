import 'package:flutter/material.dart';
// import 'package:location/location.dart' as loc; // Menggunakan alias untuk menghindari konflik jika ada
import '../services/user_service.dart';
import '../services/location_service.dart'; // Asumsi LocationService mengembalikan LatLng dari latlong2

// Model data sederhana untuk dropdown, bisa dipisah ke file model jika kompleks
class DropdownOption {
  final String id;
  final String name;
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
  final _plateController = TextEditingController(); // Plat Nomor
  final _odometerController = TextEditingController(); // Odometer
  final _passwordController = TextEditingController(); // Password

  String? _selectedBrandId;
  String? _selectedModelId;
  DateTime? _selectedServiceDate;

  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();

  // Contoh data untuk dropdown (gantilah dengan data dinamis jika perlu)
  final List<DropdownOption> _brands = [
    DropdownOption('honda', 'Honda'),
    DropdownOption('yamaha', 'Yamaha'),
    DropdownOption('suzuki', 'Suzuki'),
    DropdownOption('kawasaki', 'Kawasaki'),
  ];

  final Map<String, List<DropdownOption>> _models = {
    'honda': [
      DropdownOption('beat', 'Beat'),
      DropdownOption('vario', 'Vario'),
      DropdownOption('pcx', 'PCX')
    ],
    'yamaha': [
      DropdownOption('nmax', 'NMAX'),
      DropdownOption('aerox', 'Aerox'),
      DropdownOption('mio', 'Mio')
    ],
    // Tambahkan model lain
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
      lastDate: DateTime.now(), // Tanggal servis terakhir tidak boleh di masa depan
    );
    if (picked != null && picked != _selectedServiceDate) {
      setState(() {
        _selectedServiceDate = picked;
      });
    }
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      // Ambil lokasi GPS pengguna (asumsi LocationService sudah dihandle dengan baik)
      // final locationData = await _locationService.getCurrentLocation(); // Mengembalikan LatLng?

      // if (locationData == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('GPS tidak tersedia atau izin ditolak!')),
      //   );
      //   return;
      // }

      // Kumpulkan semua data
      // Anda perlu menyesuaikan metode registerUser di UserService
      // untuk menerima semua field baru ini.
      try {
        // Simulasi, karena UserService Anda saat ini hanya menerima beberapa parameter.
        // Anda HARUS mengupdate UserService.registerUser
        await _userService.registerUser(
          _nameController.text,
          _emailController.text,
          _addressController.text,
          _selectedModelId ?? 'N/A', // Atau brand + model
          // locationData, // Kirim LatLng
          // Tambahkan parameter baru di UserService:
          plateNumber: _plateController.text,
          lastServiceDate: _selectedServiceDate,
          brand: _selectedBrandId,
          currentOdometer: int.tryParse(_odometerController.text) ?? 0,
          password: _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoCare'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField(controller: _nameController, label: 'Nama Lengkap', hint: 'Rizky Alifian Ilham'),
              const SizedBox(height: 15),
              _buildTextField(controller: _emailController, label: 'Email', hint: 'rizky@email.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(controller: _addressController, label: 'Alamat', hint: 'Trini RT04/RW09', maxLines: 2),
              const SizedBox(height: 15),
              _buildDateField(context),
              const SizedBox(height: 15),
              _buildTextField(controller: _plateController, label: 'Plat Nomor', hint: 'K 5036 AZF'),
              const SizedBox(height: 15),
              _buildDropdownField(
                label: 'Brand',
                hint: 'Pilih Brand',
                value: _selectedBrandId,
                items: _brands,
                onChanged: (value) {
                  setState(() {
                    _selectedBrandId = value;
                    _selectedModelId = null;
                    _currentModels = _models[_selectedBrandId!] ?? [];
                  });
                },
              ),
              const SizedBox(height: 15),
              if (_selectedBrandId != null && _currentModels.isNotEmpty)
                _buildDropdownField(
                  label: 'Model',
                  hint: 'Pilih Model',
                  value: _selectedModelId,
                  items: _currentModels,
                  onChanged: (value) {
                    setState(() {
                      _selectedModelId = value;
                    });
                  },
                ),
              if (_selectedBrandId != null && _currentModels.isNotEmpty) const SizedBox(height: 15),
              _buildTextField(controller: _odometerController, label: 'Odometer saat ini (km)', hint: '63589', keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(controller: _passwordController, label: 'Password', hint: '********', obscureText: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _registerUser,
                child: const Text('DAFTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator ?? (value) {
            if (value == null || value.isEmpty) {
              return '$label tidak boleh kosong';
            }
            if (label == 'Email' && !value.contains('@')) {
                return 'Format email tidak valid';
            }
            if (label.contains('Odometer') && int.tryParse(value) == null) {
                return 'Odometer harus angka';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal Terakhir Servis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: _selectedServiceDate == null ? 'dd/mm/yyyy' : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  _selectedServiceDate == null
                      ? 'Pilih Tanggal'
                      : "${_selectedServiceDate!.day}/${_selectedServiceDate!.month}/${_selectedServiceDate!.year}",
                  style: TextStyle(color: _selectedServiceDate == null ? Colors.grey[500] : Colors.black87),
                ),
                Icon(Icons.calendar_today, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
         // Tambahkan validator jika field ini wajib
        // if (_selectedServiceDate == null && _formKey.currentState != null && _formKey.currentState!.validate())
        // Padding(
        //   padding: const EdgeInsets.only(top: 8.0),
        //   child: Text("Tanggal servis wajib diisi", style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
        // )
      ],
    );
  }

   Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownOption> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(hintText: hint),
          value: value,
          isExpanded: true,
          items: items.map((DropdownOption item) {
            return DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.name),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label belum dipilih';
            }
            return null;
          },
        ),
      ],
    );
  }
}