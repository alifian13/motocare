// lib/screens/home_screen.dart
import 'dart:async'; // Untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc; // Alias untuk location package
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

// Impor stream dari main.dart
// Pastikan path ini benar. Jika main.dart ada di folder lib/, maka cukup 'main.dart'
// Jika struktur Anda berbeda, sesuaikan. Diasumsikan main.dart ada di level yang sama dengan folder screens
import '../../main.dart'; // <-- PERHATIKAN PATH INI

import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/vehicle_service.dart';
import '../services/location_service.dart'; // Service Anda
import '../widgets/app_drawer.dart';
import '../models/user_data_model.dart';
import '../models/vehicle_model.dart';
import '../models/schedule_item.dart';
import '../models/trip_model.dart';
import '../models/service_history_item.dart';
import 'notification_list_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();
  final LocationService _locationService = LocationService();

  UserData? _displayData;
  Vehicle? _primaryVehicle;
  List<ScheduleItem> _upcomingSchedules = [];
  List<Trip> _recentTrips = [];
  List<ServiceHistoryItem> _serviceHistoryForEstimates = [];
  bool _isLoadingTrips = false;
  bool _isLoading = true;
  String _userNameForAppBar = "Pengguna";
  String _appBarTitle = "MotoCare Dashboard";
  String? _currentVehicleIdForTracking;
  late SharedPreferences prefs;

  String _liveOdometerDisplay = "0 km";
  String _liveCoordinatesDisplay = "Mencari lokasi...";
  int _odometerSnapshotAtTrackingStart = 0;

  TentativeTripData? _pendingTripConfirmationData;
  StreamSubscription? _notificationPayloadSubscription;

  static const String _oliMesinServiceType = "Ganti Oli Mesin";
  static const int _defaultOilChangeIntervalMonths = 3;
  static const int _oilServiceIntervalKm = 2000;
  static const int _serviceReminderKmThreshold =
      5; // Notifikasi jika kurang dari 5 KM

  final String _baseImageUrl = "https://motocares.my.id";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPrefsAndLoadData();
    _requestNotificationPermissionIfNeeded();
    _setupNotificationClickListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("[HomeScreen] App resumed. Memeriksa notifikasi servis...");
      if (_primaryVehicle != null && _upcomingSchedules.isNotEmpty) {
        _checkUpcomingServicesAndNotify(isInitialCheck: false);
      }
    }
  }

  void _setupNotificationClickListener() {
    _notificationPayloadSubscription =
        notificationPayloadStream.stream.listen((payload) {
      if (!mounted) return; // Pastikan widget masih ada di tree
      print("[HomeScreen] Payload notifikasi diterima via stream: $payload");
      if (payload == "confirm_trip_via_stop_notification") {
        if (_pendingTripConfirmationData != null) {
          print(
              "[HomeScreen] Menampilkan dialog konfirmasi perjalanan untuk data pending.");
          _showTripConfirmationDialog(_pendingTripConfirmationData!);
        } else {
          print(
              "[HomeScreen] Payload 'confirm_trip_via_stop_notification' diterima, tapi tidak ada data perjalanan pending.");
        }
      } else if (payload != null &&
          payload.startsWith("service_reminder_odo_")) {
        print(
            "[HomeScreen] Notifikasi servis di-tap, payload: $payload. Navigasi ke Jadwal.");
        if (_primaryVehicle != null) {
          Navigator.pushNamed(context, ScheduleScreen.routeName, arguments: {
            'vehicleId': _primaryVehicle!.vehicleId.toString(),
            'plateNumber': _primaryVehicle!.plateNumber,
          });
        }
      }
    });
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? currentPermissionStatus =
          await androidImplementation?.areNotificationsEnabled();
      print(
          "[HomeScreen] Status Izin Notifikasi Android saat ini: $currentPermissionStatus");

      if (currentPermissionStatus != null && !currentPermissionStatus) {
        print("[HomeScreen] Izin notifikasi belum ada, meminta...");
        final bool? permissionGranted =
            await androidImplementation?.requestNotificationsPermission();
        if (permissionGranted != null && permissionGranted) {
          print(
              "[HomeScreen] Izin notifikasi DIBERIKAN oleh pengguna setelah diminta.");
        } else {
          print(
              "[HomeScreen] Izin notifikasi DITOLAK oleh pengguna setelah diminta.");
        }
      } else if (currentPermissionStatus == null) {
        print(
            "[HomeScreen] Tidak dapat memeriksa status izin notifikasi (mungkin platform < Android 13).");
      } else {
        print("[HomeScreen] Izin notifikasi sudah diberikan.");
      }
    }
  }

  Future<void> _initPrefsAndLoadData() async {
    prefs = await SharedPreferences.getInstance();
    await _loadInitialDashboardData(checkServiceNotif: true);
  }

  Future<void> _loadInitialDashboardData(
      {bool checkServiceNotif = true}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _upcomingSchedules = [];
      _recentTrips = [];
      _serviceHistoryForEstimates = [];
      _liveCoordinatesDisplay = _currentVehicleIdForTracking != null
          ? "Memulai pelacakan..."
          : "Pelacakan tidak aktif.";
    });

    _userNameForAppBar =
        prefs.getString(UserService.prefUserName) ?? "Pengguna";
    String? userEmail = prefs.getString(UserService.prefUserEmail);
    String? userPhotoUrlFromPrefs =
        prefs.getString(UserService.prefUserPhotoUrl);

    final List<Vehicle> vehicleList = await _vehicleService.getMyVehicles();
    Vehicle? fetchedPrimaryVehicle;

    if (vehicleList.isNotEmpty) {
      fetchedPrimaryVehicle = vehicleList.first;
      _currentVehicleIdForTracking = fetchedPrimaryVehicle.vehicleId.toString();
      await prefs.setString(
          UserService.prefCurrentVehicleId, _currentVehicleIdForTracking!);
    } else {
      _currentVehicleIdForTracking = null;
      await prefs.remove(UserService.prefCurrentVehicleId);
    }

    if (_currentVehicleIdForTracking != null && fetchedPrimaryVehicle != null) {
      try {
        _upcomingSchedules =
            await _vehicleService.getSchedules(_currentVehicleIdForTracking!);
        _serviceHistoryForEstimates = await _vehicleService
            .getServiceHistory(_currentVehicleIdForTracking!);
        print(
            "[HomeScreen] Jadwal (${_upcomingSchedules.length}) & Riwayat servis (${_serviceHistoryForEstimates.length}) dimuat untuk kendaraan ID: $_currentVehicleIdForTracking");
      } catch (e) {
        print(
            "[HomeScreen] Error mengambil jadwal atau riwayat untuk kendaraan ID $_currentVehicleIdForTracking: $e");
      }
    }

    if (mounted) {
      setState(() {
        _primaryVehicle = fetchedPrimaryVehicle;
        if (_primaryVehicle != null) {
          _odometerSnapshotAtTrackingStart = _primaryVehicle!.currentOdometer;
          _liveOdometerDisplay =
              "${NumberFormat.decimalPattern('id_ID').format(_primaryVehicle!.currentOdometer)} km";
          _appBarTitle = _primaryVehicle!.model;
          if (checkServiceNotif) {
            print(
                "[HomeScreen] Memanggil _checkUpcomingServicesAndNotify dari _loadInitialDashboardData.");
            _checkUpcomingServicesAndNotify(isInitialCheck: true);
          }
        } else {
          _liveOdometerDisplay = "N/A";
          _appBarTitle = 'MotoCare Dashboard';
        }
        _displayData = UserData.combine(
          {
            'name': _userNameForAppBar,
            'email': userEmail,
            'userPhotoUrl': userPhotoUrlFromPrefs
          },
          _primaryVehicle,
        );
      });
    }

    if (_primaryVehicle != null) {
      await _loadRecentTrips();
    }

    bool isCurrentlyTracking = _locationService.isTrackingActive();
    print(
        "[HomeScreen] Status pelacakan saat ini: $isCurrentlyTracking. ID Kendaraan untuk dilacak: $_currentVehicleIdForTracking");

    if (_currentVehicleIdForTracking != null && !isCurrentlyTracking) {
      print(
          "[HomeScreen] Memulai pelacakan untuk kendaraan: $_currentVehicleIdForTracking");
      _odometerSnapshotAtTrackingStart = _primaryVehicle?.currentOdometer ?? 0;
      _locationService.startTracking(
        // Hapus BuildContext jika LocationService.startTracking tidak lagi membutuhkannya
        // context,
        onLiveLocationUpdate: _handleLiveLocationUpdate,
        onMotorStoppedWithData: _handleMotorStoppedWithData,
      );
      if (mounted)
        setState(() {
          _liveCoordinatesDisplay = "Pelacakan dimulai...";
        });
    } else if (_currentVehicleIdForTracking == null && isCurrentlyTracking) {
      _locationService.stopTracking();
      print(
          "[HomeScreen] Pelacakan dihentikan karena tidak ada kendaraan yang aktif.");
      if (mounted)
        setState(() {
          _liveCoordinatesDisplay = "Pelacakan dihentikan.";
        });
    } else if (_currentVehicleIdForTracking != null && isCurrentlyTracking) {
      print(
          "[HomeScreen] Pelacakan sudah aktif untuk kendaraan: $_currentVehicleIdForTracking");
      if (mounted)
        setState(() {
          _liveCoordinatesDisplay = "Pelacakan aktif...";
        });
    } else {
      print(
          "[HomeScreen] Pelacakan tidak dimulai: Tidak ada kendaraan aktif atau pelacakan sudah berjalan dengan kondisi sesuai.");
      if (mounted)
        setState(() {
          _liveCoordinatesDisplay = "Pelacakan tidak aktif.";
        });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLiveLocationUpdate(
      loc.LocationData currentLocation, double accumulatedSegmentDistanceKm) {
    if (!mounted) return;
    double totalLiveOdometerDouble =
        _odometerSnapshotAtTrackingStart.toDouble() +
            accumulatedSegmentDistanceKm;
    NumberFormat odometerFormatter = NumberFormat("#,##0.0", "id_ID");
    if (accumulatedSegmentDistanceKm == 0.0 &&
        totalLiveOdometerDouble ==
            _odometerSnapshotAtTrackingStart.toDouble()) {
      _liveOdometerDisplay =
          "${NumberFormat.decimalPattern('id_ID').format(_odometerSnapshotAtTrackingStart)} km";
    } else {
      _liveOdometerDisplay =
          "${odometerFormatter.format(totalLiveOdometerDouble)} km";
    }

    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      _liveCoordinatesDisplay =
          "Lat: ${currentLocation.latitude!.toStringAsFixed(5)}, Lon: ${currentLocation.longitude!.toStringAsFixed(5)}";
    } else {
      _liveCoordinatesDisplay = "Koordinat saat ini tidak tersedia";
    }
    setState(() {});
  }

  void _handleMotorStoppedWithData(TentativeTripData tentativeData) {
    print(
        "[HomeScreen] _handleMotorStoppedWithData TERPANGGIL. Jarak tentatif: ${tentativeData.distanceKm} km");

    if (!mounted) {
      print(
          "[HomeScreen] _handleMotorStoppedWithData: Widget tidak mounted, abaikan.");
      return;
    }
    // Hanya proses jika tidak ada konfirmasi yang sudah pending
    if (_pendingTripConfirmationData != null) {
      print(
          "[HomeScreen] _handleMotorStoppedWithData: Sudah ada data perjalanan pending, abaikan trigger baru.");
      return;
    }

    setState(() {
      _pendingTripConfirmationData = tentativeData;
    });

    String locationInfo = "di lokasi terakhir terdeteksi.";
    if (tentativeData.endLocation.latitude != null &&
        tentativeData.endLocation.longitude != null) {
      locationInfo =
          "di sekitar Lat: ${tentativeData.endLocation.latitude!.toStringAsFixed(3)}, Lon: ${tentativeData.endLocation.longitude!.toStringAsFixed(3)}.";
    }

    print(
        "[HomeScreen] MEMICU NOTIFIKASI MOTOR BERHENTI (15 detik)... Payload: confirm_trip_via_stop_notification");
    _notificationService.showLocalNotification(
        id: 2,
        title: "Motor Berhenti Terdeteksi",
        body: "Motor Anda berhenti ${locationInfo}. Konfirmasi perjalanan?",
        payload: "confirm_trip_via_stop_notification");
  }

  // Hapus _handleTripDetected karena alur konfirmasi diubah total
  // Future<void> _handleTripDetected(...) async { ... } // DIHAPUS/TIDAK DIGUNAKAN LAGI UNTUK ALUR UTAMA

  Future<void> _showTripConfirmationDialog(TentativeTripData tripData) async {
    if (!mounted) return;

    // Reset data pending agar tidak muncul dialog dobel jika notif diklik lagi dengan cepat
    // atau jika ada trigger baru saat dialog masih tampil (meskipun kecil kemungkinannya)
    final currentPendingData = _pendingTripConfirmationData;
    setState(() {
      _pendingTripConfirmationData = null;
    });

    if (currentPendingData == null || _primaryVehicle == null) {
      print(
          "[HomeScreen] Tidak bisa menampilkan dialog konfirmasi: data pending null atau primaryVehicle null.");
      _locationService.resetCurrentTripDetection();
      return;
    }

    bool? useMotor = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext alertContext) => AlertDialog(
        title: const Text('Konfirmasi Perjalanan'),
        content: Text(
            'Perjalanan sekitar ${currentPendingData.distanceKm.toStringAsFixed(2)} km terdeteksi berakhir. Apakah Anda menggunakan motor ${_primaryVehicle!.plateNumber} untuk perjalanan ini?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Tidak'),
            onPressed: () => Navigator.of(alertContext).pop(false),
          ),
          ElevatedButton(
            child: const Text('Ya, Simpan'),
            onPressed: () => Navigator.of(alertContext).pop(true),
          ),
        ],
      ),
    );

    if (useMotor == true) {
      print("[HomeScreen] Pengguna KONFIRMASI YA untuk perjalanan.");
      final Map<String, dynamic> tripPayload = {
        'distance_km': currentPendingData.distanceKm,
        'start_time': currentPendingData.startTime.toIso8601String(),
        'end_time': currentPendingData.endTime.toIso8601String(),
        if (currentPendingData.startLocation.latitude != null)
          'start_latitude': currentPendingData.startLocation.latitude,
        if (currentPendingData.startLocation.longitude != null)
          'start_longitude': currentPendingData.startLocation.longitude,
        if (currentPendingData.endLocation.latitude != null)
          'end_latitude': currentPendingData.endLocation.latitude,
        if (currentPendingData.endLocation.longitude != null)
          'end_longitude': currentPendingData.endLocation.longitude,
      };
      final result = await _vehicleService.addTrip(
          _primaryVehicle!.vehicleId.toString(), tripPayload);

      if (mounted) {
        if (result['success']) {
          final newOdometerRaw = result['data']?['newOdometer'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Perjalanan ${currentPendingData.distanceKm.toStringAsFixed(2)} km berhasil dicatat!')),
          );
          if (newOdometerRaw != null) {
            setState(() {
              int updatedOdometer;
              if (newOdometerRaw is int) {
                updatedOdometer = newOdometerRaw;
              } else if (newOdometerRaw is String) {
                updatedOdometer = int.tryParse(newOdometerRaw) ??
                    _primaryVehicle!.currentOdometer;
              } else if (newOdometerRaw is double) {
                updatedOdometer = newOdometerRaw.round();
              } else {
                updatedOdometer = _primaryVehicle!.currentOdometer;
              }
              _primaryVehicle!.currentOdometer = updatedOdometer;
              _odometerSnapshotAtTrackingStart =
                  updatedOdometer; // Penting untuk update snapshot
              _liveOdometerDisplay =
                  "${NumberFormat.decimalPattern('id_ID').format(updatedOdometer)} km";
            });
            print(
                "[HomeScreen] Odometer diperbarui ke: ${_primaryVehicle!.currentOdometer}. Memeriksa notifikasi servis.");
            _checkUpcomingServicesAndNotify(
                isInitialCheck: false); // Cek setelah perjalanan dicatat
          }
          await _loadRecentTrips(); // Muat ulang riwayat perjalanan
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result['message'] ?? 'Gagal mencatat perjalanan.')),
          );
        }
      }
    } else {
      print(
          "[HomeScreen] Pengguna KONFIRMASI TIDAK atau menutup dialog untuk perjalanan.");
    }

    _locationService.resetCurrentTripDetection();
    if (mounted) {
      setState(() {
        // _pendingTripConfirmationData sudah di-null-kan di awal
        _liveCoordinatesDisplay = "Siap untuk perjalanan baru...";
      });
    }
  }

  Future<void> _checkUpcomingServicesAndNotify(
      {required bool isInitialCheck}) async {
    if (!mounted || _primaryVehicle == null || _upcomingSchedules.isEmpty) {
      // print("[HomeScreen] _checkUpcomingServicesAndNotify: Kondisi tidak terpenuhi (not mounted, no vehicle, or no schedules).");
      return;
    }

    print(
        "[HomeScreen] Memeriksa jadwal servis untuk notifikasi. InitialCheck: $isInitialCheck. Odo Saat Ini: ${_primaryVehicle!.currentOdometer}");
    int currentOdo = _primaryVehicle!.currentOdometer;

    for (var schedule in _upcomingSchedules) {
      if (schedule.nextDueOdometer != null &&
          (schedule.status?.toUpperCase() == "UPCOMING" ||
              schedule.status?.toUpperCase() == "PENDING" ||
              schedule.status == null)) {
        // Anggap null sebagai pending/upcoming

        int kmRemaining = schedule.nextDueOdometer! - currentOdo;
        String serviceName = schedule.itemName;
        int scheduleId = schedule.scheduleId;
        int targetOdo = schedule.nextDueOdometer!;

        String prefKeyReminder =
            'notified_reminder_service_${scheduleId}_odo_${targetOdo}';
        String prefKeyOverdue =
            'notified_overdue_service_${scheduleId}_odo_${targetOdo}';

        if (kmRemaining > 0 && kmRemaining <= _serviceReminderKmThreshold) {
          bool alreadyNotifiedReminder =
              prefs.getBool(prefKeyReminder) ?? false;
          if (!alreadyNotifiedReminder || isInitialCheck) {
            print(
                "[HomeScreen] SERVIS MENDEKAT: $serviceName tinggal $kmRemaining km lagi. Mengirim notifikasi...");
            await _notificationService.showLocalNotification(
                id: 3000 + scheduleId, // ID unik
                title: "Pengingat Servis Segera",
                body:
                    "Waktunya servis $serviceName! Tinggal $kmRemaining km lagi (Target: $targetOdo km).",
                payload: "service_reminder_odo_${scheduleId}");
            await prefs.setBool(prefKeyReminder, true);
            await prefs.remove(
                prefKeyOverdue); // Reset flag overdue jika sudah tidak overdue
          } else {
            // print("[HomeScreen] Servis $serviceName ($kmRemaining km lagi) sudah pernah dinotifikasi (reminder).");
          }
        } else if (kmRemaining <= 0) {
          // Sudah terlewat atau pas
          bool alreadyNotifiedOverdue = prefs.getBool(prefKeyOverdue) ?? false;
          if (!alreadyNotifiedOverdue || isInitialCheck) {
            print(
                "[HomeScreen] SERVIS TERLEWAT (ODO): $serviceName. Odo saat ini: $currentOdo, Target: $targetOdo. Mengirim notifikasi...");
            await _notificationService.showLocalNotification(
                id: 4000 + scheduleId, // ID unik berbeda
                title: "PERHATIAN: Servis Terlewat!",
                body:
                    "Servis $serviceName sudah melewati batas odometer (Target: $targetOdo km). Segera lakukan servis!",
                payload: "service_overdue_odo_${scheduleId}");
            await prefs.setBool(prefKeyOverdue, true);
            await prefs.remove(
                prefKeyReminder); // Reset flag reminder jika sudah overdue
          } else {
            // print("[HomeScreen] Servis $serviceName (terlewat) sudah pernah dinotifikasi (overdue).");
          }
        } else {
          // Masih jauh
          // Reset flag jika servis masih jauh, agar bisa dinotifikasi lagi nanti
          if (prefs.containsKey(prefKeyReminder))
            await prefs.remove(prefKeyReminder);
          if (prefs.containsKey(prefKeyOverdue))
            await prefs.remove(prefKeyOverdue);
        }
      }
    }
  }

  Future<void> _showManualOdometerUpdateDialog() async {
    if (_primaryVehicle == null || _currentVehicleIdForTracking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tidak ada kendaraan aktif untuk diupdate odometernya.')),
      );
      return;
    }
    final TextEditingController odometerInputController =
        TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    int? newOdometerValue = await showDialog<int?>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Update Odometer Manual'),
            content: Form(
                key: dialogFormKey,
                child: TextFormField(
                  controller: odometerInputController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Odometer Baru (km)',
                      hintText: 'Masukkan angka odometer'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Odometer tidak boleh kosong';
                    }
                    final int? newOdo = int.tryParse(value);
                    if (newOdo == null) {
                      return 'Masukkan angka yang valid';
                    }
                    if (newOdo <= (_primaryVehicle?.currentOdometer ?? 0)) {
                      return 'Odometer baru harus lebih besar dari saat ini (${_primaryVehicle?.currentOdometer ?? 0} km)';
                    }
                    return null;
                  },
                )),
            actions: <Widget>[
              TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(dialogContext).pop(null)),
              TextButton(
                  child: const Text('Update'),
                  onPressed: () {
                    if (dialogFormKey.currentState!.validate()) {
                      Navigator.of(dialogContext)
                          .pop(int.parse(odometerInputController.text));
                    }
                  }),
            ],
          );
        });

    if (newOdometerValue != null) {
      final result = await _vehicleService.updateOdometerManually(
          _currentVehicleIdForTracking!, newOdometerValue);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Odometer berhasil diperbarui menjadi $newOdometerValue km.')));
          setState(() {
            _primaryVehicle!.currentOdometer = newOdometerValue;
            _odometerSnapshotAtTrackingStart = newOdometerValue;
            _liveOdometerDisplay =
                "${NumberFormat.decimalPattern('id_ID').format(newOdometerValue)} km";
            _displayData = UserData.combine({
              'name': _userNameForAppBar,
              'email': prefs.getString(UserService.prefUserEmail),
              'userPhotoUrl': prefs.getString(UserService.prefUserPhotoUrl)
            }, _primaryVehicle);
          });
          // Muat ulang data dashboard, termasuk jadwal, lalu cek notifikasi servis
          await _loadInitialDashboardData(checkServiceNotif: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message'] ?? 'Gagal update odometer.')));
        }
      }
    }
  }

  Future<void> _loadRecentTrips() async {
    if (_primaryVehicle == null || _primaryVehicle!.vehicleId == 0) {
      if (mounted) setState(() => _recentTrips = []);
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoadingTrips = true;
    });
    try {
      _recentTrips = await _vehicleService
          .getRecentTrips(_primaryVehicle!.vehicleId.toString(), limit: 3);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal memuat riwayat perjalanan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _userService.logoutUser();
    _locationService.stopTracking();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, LoginScreen.routeName, (route) => false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationPayloadSubscription?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  ScheduleItem? _getScheduleByType(String serviceType) {
    try {
      return _upcomingSchedules.firstWhere((s) =>
          s.itemName.toLowerCase() == serviceType.toLowerCase() &&
          (s.status?.toUpperCase() != 'COMPLETED' &&
              s.status?.toUpperCase() != 'SKIPPED'));
    } catch (e) {
      return null;
    }
  }

  DateTime? _getLastOilServiceDate() {
    try {
      final oilServices = _serviceHistoryForEstimates
          .where((h) =>
              h.serviceType.toLowerCase() == _oliMesinServiceType.toLowerCase())
          .toList();
      if (oilServices.isNotEmpty) {
        oilServices.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
        return oilServices.first.serviceDate;
      }
    } catch (e) {
      print("[HomeScreen] Error getting last oil service date: $e");
    }
    if (_primaryVehicle != null &&
        _primaryVehicle!.lastServiceDate != null &&
        _primaryVehicle!.lastServiceDate!.isNotEmpty) {
      return DateTime.tryParse(_primaryVehicle!.lastServiceDate!);
    }
    return null;
  }

  int _getLastOilServiceOdometer() {
    try {
      final oilServices = _serviceHistoryForEstimates
          .where((h) =>
              h.serviceType.toLowerCase() == _oliMesinServiceType.toLowerCase())
          .toList();
      if (oilServices.isNotEmpty) {
        oilServices
            .sort((a, b) => b.odometerAtService.compareTo(a.odometerAtService));
        return oilServices.first.odometerAtService;
      }
    } catch (e) {
      print("[HomeScreen] Error getting last oil service odometer: $e");
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final ScheduleItem? oliSchedule = _getScheduleByType(_oliMesinServiceType);

    int kmRemainingForOli = 0;
    String nextOliServiceInfo = "Jadwal oli belum tersedia";
    String daysRemainingForOli = "Estimasi - Hari";
    String lastOilServiceDateFormatted = "N/A";
    String kmRemainingOliText = "0 Km Lagi";

    if (_primaryVehicle != null) {
      DateTime? lastActualOilServiceDate = _getLastOilServiceDate();
      int lastOdoAtOilService = _getLastOilServiceOdometer();

      if (lastActualOilServiceDate != null) {
        lastOilServiceDateFormatted =
            DateFormat('dd MMM yy', 'id_ID').format(lastActualOilServiceDate);
      } else {
        lastOilServiceDateFormatted = "Belum ada data";
      }

      int targetOdoForDisplay;
      String kmEstSuffix = "";

      if (oliSchedule != null && oliSchedule.nextDueOdometer != null) {
        targetOdoForDisplay = oliSchedule.nextDueOdometer!;
        nextOliServiceInfo =
            "Target berikutnya di ${NumberFormat.decimalPattern('id_ID').format(targetOdoForDisplay)} km";
      } else {
        if (lastOdoAtOilService > 0) {
          targetOdoForDisplay = lastOdoAtOilService + _oilServiceIntervalKm;
        } else {
          targetOdoForDisplay = _oilServiceIntervalKm;
        }
        nextOliServiceInfo =
            "Target berikutnya ~${NumberFormat.decimalPattern('id_ID').format(targetOdoForDisplay)} km (Est)";
        kmEstSuffix = " (Est)";
      }

      kmRemainingForOli = targetOdoForDisplay > _primaryVehicle!.currentOdometer
          ? targetOdoForDisplay - _primaryVehicle!.currentOdometer
          : 0;
      kmRemainingOliText =
          "${NumberFormat.decimalPattern('id_ID').format(kmRemainingForOli)} Km Lagi$kmEstSuffix";

      if (oliSchedule != null) {
        if (oliSchedule.status?.toUpperCase() == "OVERDUE") {
          daysRemainingForOli = "TERLEWAT!";
        } else if (oliSchedule.status?.toUpperCase() == "UPCOMING") {
          daysRemainingForOli = "SEGERA!";
        } else if (oliSchedule.nextDueDate != null) {
          final now = DateTime.now();
          final DateFormat formatter = DateFormat('yyyy-MM-dd');
          final DateTime today = DateTime.parse(formatter.format(now));
          final DateTime dueDate =
              DateTime.parse(formatter.format(oliSchedule.nextDueDate!));

          if (dueDate.isAfter(today)) {
            final difference = dueDate.difference(today).inDays;
            daysRemainingForOli = "$difference Hari Lagi";
          } else if (dueDate.isAtSameMomentAs(today)) {
            daysRemainingForOli = "Hari Ini!";
          } else {
            daysRemainingForOli = "TERLEWAT!";
          }
        } else {
          if (lastActualOilServiceDate != null) {
            DateTime estimatedNextDate = DateTime(
                lastActualOilServiceDate.year,
                lastActualOilServiceDate.month +
                    _defaultOilChangeIntervalMonths,
                lastActualOilServiceDate.day);
            final now = DateTime.now();
            final DateFormat formatter = DateFormat('yyyy-MM-dd');
            final DateTime today = DateTime.parse(formatter.format(now));
            final DateTime estNextDateNormalized =
                DateTime.parse(formatter.format(estimatedNextDate));

            if (estNextDateNormalized.isAfter(today)) {
              final difference = estNextDateNormalized.difference(today).inDays;
              daysRemainingForOli = "~$difference Hari Lagi (Est)";
            } else {
              daysRemainingForOli = "Segera (Est)";
            }
          } else {
            daysRemainingForOli = "Data tanggal kurang";
          }
        }
      } else {
        if (lastActualOilServiceDate != null) {
          DateTime estimatedNextDate = DateTime(
              lastActualOilServiceDate.year,
              lastActualOilServiceDate.month + _defaultOilChangeIntervalMonths,
              lastActualOilServiceDate.day);
          final now = DateTime.now();
          final DateFormat formatter = DateFormat('yyyy-MM-dd');
          final DateTime today = DateTime.parse(formatter.format(now));
          final DateTime estNextDateNormalized =
              DateTime.parse(formatter.format(estimatedNextDate));

          if (estNextDateNormalized.isAfter(today)) {
            final difference = estNextDateNormalized.difference(today).inDays;
            daysRemainingForOli = "~$difference Hari Lagi (Est)";
          } else {
            daysRemainingForOli = "Segera Periksa (Est)";
          }
        } else {
          daysRemainingForOli = "Data tanggal kurang";
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Memuat...' : _appBarTitle),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              onPressed: () => Navigator.pushNamed(
                  context, NotificationListScreen.routeName)),
          IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: _handleLogout),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _primaryVehicle == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_transfer_outlined,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Anda belum memiliki kendaraan terdaftar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan tambahkan kendaraan melalui menu profil atau saat registrasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_outlined),
                            label: const Text('Coba Lagi Memuat Data'),
                            onPressed: () => _loadInitialDashboardData(
                                checkServiceNotif: true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.black87))
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      _loadInitialDashboardData(checkServiceNotif: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 70.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 10),
                        _buildLiveCoordinatesCard(),
                        const SizedBox(height: 16),
                        _buildOdometerCard(),
                        const SizedBox(height: 20),
                        _buildServiceInfoCard(
                          title: oliSchedule?.itemName ?? _oliMesinServiceType,
                          lastServiceDate: lastOilServiceDateFormatted,
                          nextServiceInfo: nextOliServiceInfo,
                          daysRemaining: daysRemainingForOli,
                          kmRemaining: kmRemainingOliText,
                          icon: Icons.opacity_outlined,
                          status: oliSchedule?.status,
                        ),
                        _buildTripTimeline(),
                        const SizedBox(height: 30),
                        _buildNavigationGrid(),
                        const SizedBox(height: 20),
                        if (_locationService.isTrackingActive() &&
                            _currentVehicleIdForTracking != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    color: Colors.green.shade700, size: 16),
                                const SizedBox(width: 6),
                                Text("Pelacakan perjalanan aktif",
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12)),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off_outlined,
                                    color: Colors.red.shade700, size: 16),
                                const SizedBox(width: 6),
                                Text("Pelacakan perjalanan tidak aktif",
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    if (_displayData == null || _primaryVehicle == null)
      return const SizedBox.shrink();
    String? userPhotoPath = _displayData!.userPhotoUrl;
    String vehicleBrand = _primaryVehicle!.brand;
    String vehicleModelString = _primaryVehicle!.model;
    String? vehicleLogoPath = _primaryVehicle!.logoUrl;

    ImageProvider<Object> userAvatarImage;
    if (userPhotoPath != null && userPhotoPath.isNotEmpty) {
      if (userPhotoPath.startsWith('http')) {
        userAvatarImage = NetworkImage(userPhotoPath);
      } else {
        userAvatarImage = NetworkImage(_baseImageUrl + userPhotoPath);
      }
    } else {
      userAvatarImage = const AssetImage('assets/images/default_avatar.png');
    }

    Widget vehicleLogoWidget = const SizedBox.shrink();
    if (vehicleLogoPath != null && vehicleLogoPath.isNotEmpty) {
      String finalLogoUrl = vehicleLogoPath.startsWith('http')
          ? vehicleLogoPath
          : _baseImageUrl + vehicleLogoPath;
      vehicleLogoWidget = Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Image.network(
          finalLogoUrl,
          height: 60,
          width: 60,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.motorcycle_outlined,
                size: 45, color: Colors.grey.shade500);
          },
        ),
      );
    } else if (vehicleBrand.isNotEmpty) {
      vehicleLogoWidget = Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Icon(Icons.motorcycle_outlined,
              size: 45, color: Colors.grey.shade500));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: userAvatarImage,
          onBackgroundImageError: (exception, stackTrace) {
            // Error
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _displayData!.name ?? "Nama Pengguna",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                (vehicleBrand.isNotEmpty && vehicleModelString.isNotEmpty)
                    ? "$vehicleBrand $vehicleModelString"
                    : (vehicleModelString.isNotEmpty
                        ? vehicleModelString
                        : vehicleBrand),
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        vehicleLogoWidget,
      ],
    );
  }

  Widget _buildLiveCoordinatesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(Icons.my_location,
                color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _liveCoordinatesDisplay,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOdometerCard() {
    if (_primaryVehicle == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Odometer Saat Ini",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
                TextButton.icon(
                  icon: Icon(Icons.edit_outlined,
                      size: 16, color: Theme.of(context).primaryColor),
                  label: Text("Update",
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).primaryColor)),
                  onPressed: _showManualOdometerUpdateDialog,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(50, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(_liveOdometerDisplay,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard({
    required String title,
    required String lastServiceDate,
    required String nextServiceInfo,
    required String daysRemaining,
    required String kmRemaining,
    required IconData icon,
    String? status,
  }) {
    Color cardColor = Colors.white;
    Color statusTextColor = Colors.grey.shade700;
    IconData statusIconData = Icons.schedule_outlined;
    Color statusIconColor = Colors.blueGrey;

    if (status != null) {
      if (status.toUpperCase() == "OVERDUE") {
        cardColor = Colors.red.shade50;
        statusTextColor = Colors.red.shade700;
        statusIconData = Icons.error_outline_rounded;
        statusIconColor = Colors.red.shade700;
      } else if (status.toUpperCase() == "UPCOMING") {
        cardColor = Colors.orange.shade50;
        statusTextColor = Colors.orange.shade700;
        statusIconData = Icons.notification_important_outlined;
        statusIconColor = Colors.orange.shade700;
      } else if (status.toUpperCase() == "PENDING") {
        cardColor = Colors.blue.shade50;
        statusTextColor = Colors.blue.shade700;
        statusIconData = Icons.hourglass_empty_outlined;
        statusIconColor = Colors.blue.shade700;
      }
    }
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 26, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 8),
            Text("Servis Oli Terakhir: $lastServiceDate",
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            const Divider(height: 16, thickness: 0.8),
            Text(nextServiceInfo,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(
                children: [
                  Icon(statusIconData, color: statusIconColor, size: 18),
                  const SizedBox(width: 4),
                  Text(daysRemaining,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor)),
                ],
              ),
              Text(kmRemaining,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600))
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
          child: Text(
            "Linimasa Perjalanan",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
        ),
        if (_isLoadingTrips)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
          )
        else if (_recentTrips.isEmpty)
          Card(
            child: const ListTile(
              leading: Icon(Icons.map_outlined, color: Colors.blueGrey),
              title: Text("Belum terdapat data perjalanan.",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTrips.length > 2 ? 2 : _recentTrips.length,
            itemBuilder: (context, index) {
              final trip = _recentTrips[index];
              String tripTimeInfo = "Waktu tidak tersedia";
              if (trip.startTime != null && trip.endTime != null) {
                final String formattedStartTime =
                    DateFormat('dd/MM HH:mm', 'id_ID').format(trip.startTime!);
                final String formattedEndTime =
                    DateFormat('HH:mm', 'id_ID').format(trip.endTime!);
                tripTimeInfo = "$formattedStartTime - $formattedEndTime";
              } else if (trip.endTime != null) {
                tripTimeInfo =
                    "Dicatat: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(trip.endTime!)}";
              }

              String locationDisplay = trip.startAddress?.isNotEmpty == true
                  ? trip.startAddress!
                  : (trip.startLatitude != null
                      ? "Dari: Koordinat"
                      : "Lokasi tidak diketahui");

              if (trip.startAddress?.isNotEmpty == true &&
                  trip.endAddress?.isNotEmpty == true &&
                  trip.endAddress != trip.startAddress) {
                locationDisplay += " → ${trip.endAddress}";
              } else if (trip.endAddress?.isNotEmpty == true) {
                locationDisplay = "Menuju: ${trip.endAddress}";
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: Icon(Icons.route_outlined,
                      color: Theme.of(context).primaryColor, size: 28),
                  title: Text(
                    locationDisplay,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    tripTimeInfo,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  trailing: Text(
                    "${trip.distanceKm.toStringAsFixed(1)} km",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNavigationGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildNavigationButton(
          icon: Icons.history_edu_outlined,
          label: "History\nPerawatan",
          onTap: () {
            if (_primaryVehicle?.vehicleId != null) {
              Navigator.pushNamed(context, HistoryScreen.routeName, arguments: {
                'vehicleId': _primaryVehicle!.vehicleId,
                'plateNumber': _primaryVehicle!.plateNumber,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Data kendaraan tidak tersedia.')));
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.event_available_outlined,
          label: "Jadwal\nPerawatan",
          onTap: () {
            if (_primaryVehicle?.vehicleId != null) {
              Navigator.pushNamed(context, ScheduleScreen.routeName,
                  arguments: {
                    'vehicleId': _primaryVehicle!.vehicleId.toString(),
                    'plateNumber': _primaryVehicle!.plateNumber,
                  });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Data kendaraan tidak tersedia.')));
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.notifications_none_outlined,
          label: "Daftar\nNotifikasi",
          onTap: () =>
              Navigator.pushNamed(context, NotificationListScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 30, color: Theme.of(context).primaryColor),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500))
        ]),
      ),
    );
  }
}
