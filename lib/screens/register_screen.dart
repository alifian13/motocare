import 'package:flutter/material.dart';
import '../services/user_service.dart';

class DropdownOption {
  final String id;
  final String name; 
  DropdownOption(this.id, this.name);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _brandController = TextEditingController(); 
  final _modelController = TextEditingController();
  final _odometerController = TextEditingController();
  final _lastServiceDateController = TextEditingController();

  final List<Map<String, dynamic>> _initialServices = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _odometerController.dispose();
    _lastServiceDateController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan dialog tambah servis awal
  Future<void> _showAddInitialServiceDialog() async {
    final dialogFormKey = GlobalKey<FormState>();
    String? serviceType;
    TextEditingController odometerController = TextEditingController();
    TextEditingController dateController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Riwayat Servis Awal'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Jenis Servis (mis: Ganti Oli)'),
                    validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                    onSaved: (value) => serviceType = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Odometer saat Servis (km)'),
                    keyboardType: TextInputType.number,
                    controller: odometerController,
                    validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tanggal Servis (YYYY-MM-DD)'),
                    controller: dateController,
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                    onTap: () async {
                      FocusScope.of(dialogContext).requestFocus(FocusNode());
                      DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now());
                      if (picked != null) {
                        dateController.text = picked.toIso8601String().substring(0, 10);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Tambah'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  dialogFormKey.currentState!.save();
                  setState(() { 
                    _initialServices.add({
                      "service_type": serviceType!,
                      "odometer_at_service": int.parse(odometerController.text),
                      "service_date": dateController.text,
                    });
                  });
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${serviceType!} ditambahkan ke riwayat awal.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      bool addInitialFlow = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Riwayat Servis Awal'),
          content: const Text('Apakah Anda ingin menambahkan riwayat servis yang dilakukan sebelumnya untuk motor ini? Tekan "Ya" untuk menambahkan satu per satu, atau "Lewati" untuk lanjut.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Lewati')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Ya, Tambahkan')),
          ],
        ),
      ) ?? false;

      if (addInitialFlow) {
        bool addMoreServices = true;
        while(addMoreServices) {
          await _showAddInitialServiceDialog(); 
          addMoreServices = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Tambah Lagi?'),
              content: const Text('Apakah ada riwayat servis lain yang ingin ditambahkan?'),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Tidak, Lanjut Daftar')),
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Ya, Tambah Lagi')),
              ],
            ),
          ) ?? false;
        }
      }

      setState(() { _isLoading = true; });

      final result = await UserService().registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        // Data Kendaraan
        plateNumber: _plateNumberController.text,
        brand: _brandController.text,
        model: _modelController.text, 
        currentOdometer: int.tryParse(_odometerController.text) ?? 0,
        lastServiceDate: _lastServiceDateController.text.isEmpty ? null : _lastServiceDateController.text,
        initialServices: _initialServices.isNotEmpty ? _initialServices : null,
      );

      setState(() { _isLoading = false; });

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['data']?['message'] ?? 'Registrasi Berhasil! Silakan login.')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Registrasi Gagal')),
          );
        }
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Theme.of(context).primaryColor) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Pilih Tanggal',
          prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        readOnly: true,
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            controller.text = pickedDate.toIso8601String().split('T').first;
          }
        },
        validator: (value) { 
          return null;
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Buat Akun MotoCare', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  "Selamat Datang!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D3B66)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Silakan isi data diri dan kendaraan Anda.",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Data Pengguna
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap Anda',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Masukkan alamat email Anda',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                    if (!value.contains('@') || !value.contains('.')) return 'Masukkan email yang valid';
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                _buildTextField(
                  controller: _addressController,
                  label: 'Alamat (Opsional)',
                  hint: 'Masukkan alamat Anda',
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 20),
                Text("Data Kendaraan Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D3B66))),
                const SizedBox(height: 15),

                // Data Kendaraan
                _buildTextField(
                  controller: _plateNumberController,
                  label: 'Nomor Polisi',
                  hint: 'Contoh: B 1234 XYZ',
                  prefixIcon: Icons.motorcycle_outlined,
                  validator: (value) => value == null || value.isEmpty ? 'Nomor polisi tidak boleh kosong' : null,
                ),
                _buildTextField( 
                  controller: _brandController,
                  label: 'Merek Motor',
                  hint: 'Contoh: Honda, Yamaha',
                  prefixIcon: Icons.branding_watermark_outlined,
                  validator: (value) => value == null || value.isEmpty ? 'Merek tidak boleh kosong' : null,
                ),
                _buildTextField( 
                  controller: _modelController,
                  label: 'Model/Tipe Motor',
                  hint: 'Contoh: Beat Street, NMAX',
                  prefixIcon: Icons.two_wheeler_outlined,
                  validator: (value) => value == null || value.isEmpty ? 'Model tidak boleh kosong' : null,
                ),
                _buildTextField(
                  controller: _odometerController,
                  label: 'Odometer Saat Ini (km)',
                  hint: 'Masukkan angka odometer',
                  prefixIcon: Icons.speed_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                     if (value == null || value.isEmpty) return 'Odometer tidak boleh kosong';
                     if (int.tryParse(value) == null) return 'Masukkan angka yang valid';
                     return null;
                  }
                ),
                _buildDateField( 
                  label: 'Tanggal Servis Terakhir (Opsional)',
                  controller: _lastServiceDateController,
                ),
                const SizedBox(height: 20),

                // daftar servis awal yang sudah ditambahkan
                if (_initialServices.isNotEmpty) ...[
                  Text("Riwayat Servis Awal Ditambahkan:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _initialServices.length,
                    itemBuilder: (ctx, index) {
                      final service = _initialServices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(Icons.build_circle_outlined, color: Theme.of(context).primaryColor),
                          title: Text(service['service_type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Odo: ${service['odometer_at_service']} km, Tgl: ${service['service_date']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                            onPressed: () {
                              setState(() {
                                _initialServices.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextButton.icon(
                  icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                  label: Text('Tambah Riwayat Servis Awal (Opsional)', style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: _showAddInitialServiceDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),

                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Daftar Akun'),
                      ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Sudah punya akun?", style: TextStyle(fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        'Login di sini',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}