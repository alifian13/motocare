// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart'; // Pastikan path ini benar
import '../models/schedule_item.dart';
import '../models/service_history_item.dart';
import '../models/trip_model.dart';
import '../models/user_data_model.dart';
import '../models/vehicle_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/vehicle_service.dart';
import '../widgets/app_drawer.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'notification_list_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // === SERVICES & CONTROLLERS ===
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();
  final LocationService _locationService = LocationService();
  StreamSubscription? _notificationPayloadSubscription;

  // === STATE VARIABLES ===
  bool _isLoading = true;
  UserData? _displayData;
  Vehicle? _primaryVehicle;
  List<ScheduleItem> _upcomingSchedules = [];
  List<ServiceHistoryItem> _serviceHistoryForEstimates = [];
  List<Trip> _recentTrips = [];
  bool _isLoadingTrips = false;
  String? _currentVehicleIdForTracking;
  late SharedPreferences prefs;

  String _liveOdometerDisplay = "0 km";
  int _odometerSnapshotAtTrackingStart = 0;

  TentativeTripData? _pendingTripConfirmationData;

  // === CONSTANTS ===
  static const String _oliMesinServiceType = "Ganti Oli Mesin";
  static const int _defaultOilChangeIntervalMonths = 3;
  static const int _oilServiceIntervalKm = 2000;
  static const int _serviceReminderKmThreshold =
      500; // Notif jika kurang 500 KM
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationPayloadSubscription?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  //============================================================================
  // BAGIAN LOGIKA & HELPER (KODE ASLI ANDA)
  //============================================================================

  void _setupNotificationClickListener() {
    _notificationPayloadSubscription =
        notificationPayloadStream.stream.listen((payload) {
      if (!mounted) return;
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
    });

    String userNameForAppBar =
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
          if (checkServiceNotif) {
            print(
                "[HomeScreen] Memanggil _checkUpcomingServicesAndNotify dari _loadInitialDashboardData.");
            _checkUpcomingServicesAndNotify(isInitialCheck: true);
          }
        } else {
          _liveOdometerDisplay = "N/A";
        }
        _displayData = UserData.combine(
          {
            'name': userNameForAppBar,
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
        onLiveLocationUpdate: _handleLiveLocationUpdate,
        onMotorStoppedWithData: _handleMotorStoppedWithData,
      );
    } else if (_currentVehicleIdForTracking == null && isCurrentlyTracking) {
      _locationService.stopTracking();
      print(
          "[HomeScreen] Pelacakan dihentikan karena tidak ada kendaraan yang aktif.");
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

    setState(() {
      if (accumulatedSegmentDistanceKm == 0.0 &&
          totalLiveOdometerDouble ==
              _odometerSnapshotAtTrackingStart.toDouble()) {
        _liveOdometerDisplay =
            "${NumberFormat.decimalPattern('id_ID').format(_odometerSnapshotAtTrackingStart)} km";
      } else {
        _liveOdometerDisplay =
            "${odometerFormatter.format(totalLiveOdometerDouble)} km";
      }
    });
  }

  void _handleMotorStoppedWithData(TentativeTripData tentativeData) {
    print(
        "[HomeScreen] _handleMotorStoppedWithData TERPANGGIL. Jarak tentatif: ${tentativeData.distanceKm} km");
    if (!mounted || _pendingTripConfirmationData != null) {
      return;
    }

    setState(() {
      _pendingTripConfirmationData = tentativeData;
    });

    _notificationService.showLocalNotification(
        id: 2,
        title: "Motor Berhenti Terdeteksi",
        body: "Motor Anda berhenti terdeteksi. Konfirmasi perjalanan?",
        payload: "confirm_trip_via_stop_notification");
  }

  Future<void> _showTripConfirmationDialog(TentativeTripData tripData) async {
    if (!mounted) return;

    final currentPendingData = _pendingTripConfirmationData;
    setState(() {
      _pendingTripConfirmationData = null;
    });

    if (currentPendingData == null || _primaryVehicle == null) {
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
              _odometerSnapshotAtTrackingStart = updatedOdometer;
              _liveOdometerDisplay =
                  "${NumberFormat.decimalPattern('id_ID').format(updatedOdometer)} km";
            });
            _checkUpcomingServicesAndNotify(isInitialCheck: false);
          }
          await _loadRecentTrips();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(result['message'] ?? 'Gagal mencatat perjalanan.')),
          );
        }
      }
    }
    _locationService.resetCurrentTripDetection();
  }

  Future<void> _checkUpcomingServicesAndNotify(
      {required bool isInitialCheck}) async {
    if (!mounted || _primaryVehicle == null || _upcomingSchedules.isEmpty) {
      return;
    }
    int currentOdo = _primaryVehicle!.currentOdometer;

    for (var schedule in _upcomingSchedules) {
      if (schedule.nextDueOdometer != null &&
          (schedule.status?.toUpperCase() == "UPCOMING" ||
              schedule.status?.toUpperCase() == "PENDING" ||
              schedule.status == null)) {
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
            await _notificationService.showLocalNotification(
                id: 3000 + scheduleId,
                title: "Pengingat Servis Segera",
                body:
                    "Waktunya servis $serviceName! Tinggal $kmRemaining km lagi (Target: $targetOdo km).",
                payload: "service_reminder_odo_${scheduleId}");
            await prefs.setBool(prefKeyReminder, true);
            await prefs.remove(prefKeyOverdue);
          }
        } else if (kmRemaining <= 0) {
          bool alreadyNotifiedOverdue = prefs.getBool(prefKeyOverdue) ?? false;
          if (!alreadyNotifiedOverdue || isInitialCheck) {
            await _notificationService.showLocalNotification(
                id: 4000 + scheduleId,
                title: "PERHATIAN: Servis Terlewat!",
                body:
                    "Servis $serviceName sudah melewati batas odometer (Target: $targetOdo km). Segera lakukan servis!",
                payload: "service_overdue_odo_${scheduleId}");
            await prefs.setBool(prefKeyOverdue, true);
            await prefs.remove(prefKeyReminder);
          }
        } else {
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
          });
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

  //============================================================================
  // BAGIAN BUILD METHOD & WIDGETS (YANG DI-DESAIN ULANG)
  //============================================================================

  @override
  Widget build(BuildContext context) {
    final ScheduleItem? oliSchedule = _getScheduleByType(_oliMesinServiceType);
    int kmRemainingForOli = 0;
    String nextOliServiceInfo = "Jadwal oli belum tersedia";
    String daysRemainingForOli = "Estimasi - Hari";
    String lastOilServiceDateFormatted = "N/A";
    String kmRemainingOliText = "0 Km Lagi";
    int lastOdoAtOilService = 0;
    int targetOdoForDisplay = 0;

    if (_primaryVehicle != null) {
      DateTime? lastActualOilServiceDate = _getLastOilServiceDate();
      lastOdoAtOilService = _getLastOilServiceOdometer();

      if (lastActualOilServiceDate != null) {
        lastOilServiceDateFormatted =
            DateFormat('dd MMM yy', 'id_ID').format(lastActualOilServiceDate);
      } else {
        lastOilServiceDateFormatted = "Belum ada data";
      }

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
        title: Text(_isLoading
            ? 'Memuat...'
            : (_primaryVehicle?.model ?? 'MotoCare Dashboard')),
        elevation: 0, // AppBar lebih flat
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_accessibility_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _primaryVehicle == null
              ? _buildNoVehicleView()
              : RefreshIndicator(
                  onRefresh: () =>
                      _loadInitialDashboardData(checkServiceNotif: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildOdometerCard(),
                        const SizedBox(height: 16),
                        _buildServiceInfoCard(
                          title: oliSchedule?.itemName ?? _oliMesinServiceType,
                          lastServiceDate: lastOilServiceDateFormatted,
                          nextServiceInfo: nextOliServiceInfo,
                          daysRemaining: daysRemainingForOli,
                          kmRemaining: kmRemainingOliText,
                          icon: Icons.opacity_outlined,
                          status: oliSchedule?.status,
                          lastOdo: lastOdoAtOilService,
                          currentOdo: _primaryVehicle!.currentOdometer,
                          nextOdo: targetOdoForDisplay,
                        ),
                        const SizedBox(height: 24),
                        _buildNavigationGrid(),
                        const SizedBox(height: 24),
                        _buildTripTimeline(),
                        const SizedBox(height: 24),
                        _buildTrackingStatus(),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// WIDGET: Menampilkan header profil pengguna dan kendaraan.
  Widget _buildProfileHeader() {
    if (_primaryVehicle == null) return const SizedBox.shrink();

    String? userPhotoPath = prefs.getString(UserService.prefUserPhotoUrl);
    ImageProvider<Object> userAvatarImage;
    if (userPhotoPath != null && userPhotoPath.isNotEmpty) {
      userAvatarImage = NetworkImage(userPhotoPath.startsWith('http')
          ? userPhotoPath
          : _baseImageUrl + userPhotoPath);
    } else {
      userAvatarImage = const AssetImage(
          'assets/images/default_avatar.png'); // Pastikan Anda punya aset ini
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          backgroundImage: userAvatarImage,
          onBackgroundImageError: (exception, stackTrace) {/* Handle error */},
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Datang,",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                prefs.getString(UserService.prefUserName) ?? "Pengguna",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Logo Kendaraan
        if (_primaryVehicle!.logoUrl != null &&
            _primaryVehicle!.logoUrl!.isNotEmpty)
          Image.network(
            _primaryVehicle!.logoUrl!.startsWith('http')
                ? _primaryVehicle!.logoUrl!
                : _baseImageUrl + _primaryVehicle!.logoUrl!,
            // === PERUBAHAN DI SINI ===
            height: 60, // Diperbesar dari 40
            width: 60, // Diperbesar dari 40
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.motorcycle, size: 50), // Disesuaikan
          )
      ],
    );
  }

  /// WIDGET: Kartu utama yang menampilkan odometer.
  Widget _buildOdometerCard() {
    return Card(
      elevation: 4.0,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
      child: InkWell(
        onTap: _showManualOdometerUpdateDialog,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.speed,
                  size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Odometer Saat Ini",
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      _liveOdometerDisplay,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.edit,
                    size: 20, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// WIDGET: Kartu informasi servis dengan progress bar.
  Widget _buildServiceInfoCard({
    required String title,
    required String lastServiceDate,
    required String nextServiceInfo,
    required String daysRemaining,
    required String kmRemaining,
    required IconData icon,
    String? status,
    required int lastOdo,
    required int currentOdo,
    required int nextOdo,
  }) {
    final theme = Theme.of(context);
    Color statusColor = theme.colorScheme.primary;
    String statusText = daysRemaining;

    if (status?.toUpperCase() == "OVERDUE" ||
        daysRemaining.contains("TERLEWAT")) {
      statusColor = theme.colorScheme.error;
      statusText = "TERLEWAT";
    } else if (status?.toUpperCase() == "UPCOMING" ||
        daysRemaining.contains("SEGERA") ||
        daysRemaining.contains("Hari Ini")) {
      statusColor = Colors.orange.shade800;
      statusText = "SEGERA";
    }

    double progress = _calculateProgress(lastOdo, currentOdo, nextOdo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: theme.primaryColorDark),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text("Servis Terakhir: $lastServiceDate",
                  style: theme.textTheme.labelSmall),
            ),
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("JADWAL BERIKUTNYA",
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(nextServiceInfo,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("ESTIMASI", style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(statusText,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: statusColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(kmRemaining, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  /// WIDGET: Grid untuk tombol navigasi utama.
  Widget _buildNavigationGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildNavigationButton(
          icon: Icons.history_edu_outlined,
          label: "Riwayat",
          onTap: () {
            if (_primaryVehicle != null) {
              Navigator.pushNamed(context, HistoryScreen.routeName, arguments: {
                'vehicleId': _primaryVehicle!.vehicleId,
                'plateNumber': _primaryVehicle!.plateNumber,
              });
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.event_note_outlined,
          label: "Jadwal",
          onTap: () {
            if (_primaryVehicle != null) {
              Navigator.pushNamed(context, ScheduleScreen.routeName,
                  arguments: {
                    'vehicleId': _primaryVehicle!.vehicleId.toString(),
                    'plateNumber': _primaryVehicle!.plateNumber,
                  });
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.notifications_outlined,
          label: "Daftar Notifikasi",
          onTap: () =>
              Navigator.pushNamed(context, NotificationListScreen.routeName),
        ),
      ],
    );
  }

  /// WIDGET: Komponen tombol untuk grid navigasi.
  Widget _buildNavigationButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  /// WIDGET: Menampilkan 3 perjalanan terakhir.
  Widget _buildTripTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Perjalanan Terakhir",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_isLoadingTrips)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator()))
        else if (_recentTrips.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.map_outlined,
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                  const SizedBox(width: 12),
                  const Text("Belum ada data perjalanan."),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTrips.length,
            itemBuilder: (context, index) {
              final trip = _recentTrips[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.route_outlined,
                        color: Theme.of(context).primaryColor),
                  ),
                  title: Text(
                    "Perjalanan ${trip.distanceKm.toStringAsFixed(1)} km",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(DateFormat('EEEE, dd MMMizzi • HH:mm', 'id_ID')
                      .format(trip.endTime!)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {/* Navigasi ke detail trip jika ada */},
                ),
              );
            },
          ),
      ],
    );
  }

  /// WIDGET: Tampilan ketika tidak ada kendaraan yang terdaftar.
  Widget _buildNoVehicleView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_transfer, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Kendaraan',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan tambahkan kendaraan utama Anda melalui menu di laci navigasi.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              onPressed: () =>
                  _loadInitialDashboardData(checkServiceNotif: true),
            )
          ],
        ),
      ),
    );
  }

  /// WIDGET: Status pelacakan di bagian bawah.
  Widget _buildTrackingStatus() {
    bool isTracking = _locationService.isTrackingActive();
    Color statusColor =
        isTracking ? Colors.green.shade700 : Colors.red.shade700;
    IconData statusIcon = isTracking ? Icons.location_on : Icons.location_off;
    String statusText = isTracking
        ? "Pelacakan perjalanan aktif"
        : "Pelacakan perjalanan tidak aktif";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Text(statusText,
              style:
                  TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// HELPER: Menghitung progres untuk LinearProgressIndicator.
  double _calculateProgress(int lastOdo, int currentOdo, int nextOdo) {
    if (nextOdo <= lastOdo) return 1.0; // Jika target tidak valid

    int totalKmForInterval = nextOdo - lastOdo;
    int kmTravelledSinceLast = currentOdo - lastOdo;

    if (kmTravelledSinceLast <= 0) return 0.0;
    if (kmTravelledSinceLast >= totalKmForInterval) return 1.0;

    return kmTravelledSinceLast / totalKmForInterval;
  }
}
