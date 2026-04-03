import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/device_service.dart';
import '../../../core/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';

class AddMeterState {
  final int currentStep;
  final String customerName;
  final String address;
  final String telephone;
  final String tariffClass;
  final String gpsCoordinates;
  final String tariffActivity;
  final String geocode;
  final String findings;
  final String initialReadings;
  final String meterId;
  final String spnNumber;
  final String meterBrand;
  final String meterRating;
  final String meterPhase;
  final String meteringType;
  final int? estimatedLoadWatts;
  final List<String> capturedImagePaths;
  final String? capturedVideoPath;
  final bool isLocationLoading;
  final bool isUploading;

  AddMeterState({
    this.currentStep = 0,
    this.customerName = '',
    this.address = '',
    this.telephone = '',
    this.tariffClass = 'E02',
    this.gpsCoordinates = '',
    this.tariffActivity = 'Residential',
    this.geocode = '',
    this.findings = '',
    this.initialReadings = '',
    this.meterId = '',
    this.spnNumber = '',
    this.meterBrand = '',
    this.meterRating = '',
    this.meterPhase = '1-Phase',
    this.meteringType = 'Postpaid',
    this.capturedImagePaths = const [],
    this.capturedVideoPath,
    this.estimatedLoadWatts,
    this.isLocationLoading = false,
    this.isUploading = false,
  });

  bool get isStep1Valid =>
      customerName.isNotEmpty && address.isNotEmpty && telephone.isNotEmpty;

  bool get isStep2Valid => meterId.isNotEmpty && meterBrand.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'currentStep': currentStep,
      'customerName': customerName,
      'address': address,
      'telephone': telephone,
      'tariffClass': tariffClass,
      'gpsCoordinates': gpsCoordinates,
      'tariffActivity': tariffActivity,
      'geocode': geocode,
      'findings': findings,
      'initialReadings': initialReadings,
      'meterId': meterId,
      'spnNumber': spnNumber,
      'meterBrand': meterBrand,
      'meterRating': meterRating,
      'meterPhase': meterPhase,
      'meteringType': meteringType,
      'capturedImagePaths': capturedImagePaths,
      'capturedVideoPath': capturedVideoPath,
      'estimatedLoadWatts': estimatedLoadWatts,
    };
  }

  factory AddMeterState.fromMap(Map<dynamic, dynamic> map) {
    // Migrate old capturedImagePath to capturedImagePaths if necessary
    List<String> images = [];
    if (map['capturedImagePaths'] != null) {
      images = List<String>.from(map['capturedImagePaths']);
    } else if (map['capturedImagePath'] != null) {
      images = [map['capturedImagePath'] as String];
    }

    return AddMeterState(
      currentStep: map['currentStep'] ?? 0,
      customerName: map['customerName'] ?? '',
      address: map['address'] ?? '',
      telephone: map['telephone'] ?? '',
      tariffClass: map['tariffClass'] ?? 'E02',
      gpsCoordinates: map['gpsCoordinates'] ?? '',
      tariffActivity: map['tariffActivity'] ?? 'Residential',
      geocode: map['geocode'] ?? '',
      findings: map['findings'] ?? '',
      initialReadings: map['initialReadings'] ?? '',
      meterId: map['meterId'] ?? '',
      spnNumber: map['spnNumber'] ?? '',
      meterBrand: map['meterBrand'] ?? '',
      meterRating: map['meterRating'] ?? '',
      meterPhase: map['meterPhase'] ?? '1-Phase',
      meteringType: map['meteringType'] ?? 'Postpaid',
      capturedImagePaths: images,
      capturedVideoPath: map['capturedVideoPath'],
      estimatedLoadWatts: map['estimatedLoadWatts'],
    );
  }

  AddMeterState copyWith({
    int? currentStep,
    String? customerName,
    String? address,
    String? telephone,
    String? tariffClass,
    String? gpsCoordinates,
    String? tariffActivity,
    String? geocode,
    String? findings,
    String? initialReadings,
    String? meterId,
    String? spnNumber,
    String? meterBrand,
    String? meterRating,
    String? meterPhase,
    String? meteringType,
    List<String>? capturedImagePaths,
    String? capturedVideoPath,
    int? estimatedLoadWatts,
    bool? isLocationLoading,
    bool? isUploading,
  }) {
    return AddMeterState(
      currentStep: currentStep ?? this.currentStep,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      telephone: telephone ?? this.telephone,
      tariffClass: tariffClass ?? this.tariffClass,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      tariffActivity: tariffActivity ?? this.tariffActivity,
      geocode: geocode ?? this.geocode,
      findings: findings ?? this.findings,
      initialReadings: initialReadings ?? this.initialReadings,
      meterId: meterId ?? this.meterId,
      spnNumber: spnNumber ?? this.spnNumber,
      meterBrand: meterBrand ?? this.meterBrand,
      meterRating: meterRating ?? this.meterRating,
      meterPhase: meterPhase ?? this.meterPhase,
      meteringType: meteringType ?? this.meteringType,
      capturedImagePaths: capturedImagePaths ?? this.capturedImagePaths,
      capturedVideoPath: capturedVideoPath ?? this.capturedVideoPath,
      estimatedLoadWatts: estimatedLoadWatts ?? this.estimatedLoadWatts,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class AddMeterNotifier extends Notifier<AddMeterState> {
  static const String _draftKey = 'add_meter_draft';

  @override
  AddMeterState build() {
    try {
      final box = Hive.box('settings');
      final draft = box.get(_draftKey);
      if (draft != null) {
        return AddMeterState.fromMap(Map<dynamic, dynamic>.from(draft));
      }
    } catch (_) {
      // Ignore errors during silent check
    }
    return AddMeterState();
  }

  Future<void> _saveDraft() async {
    final box = await Hive.openBox('settings');
    await box.put(_draftKey, state.toMap());
  }

  Future<void> reset() async {
    final box = await Hive.openBox('settings');
    await box.delete(_draftKey);
    state = AddMeterState();
  }

  void updateCustomerName(String val) {
    state = state.copyWith(customerName: val);
    _saveDraft();
  }

  void updateAddress(String val) {
    state = state.copyWith(address: val);
    _saveDraft();
  }

  void updateTelephone(String val) {
    state = state.copyWith(telephone: val);
    _saveDraft();
  }

  void updateTariffClass(String val) {
    state = state.copyWith(tariffClass: val);
    _saveDraft();
  }

  void updateGpsCoordinates(String val) {
    state = state.copyWith(gpsCoordinates: val);
    _saveDraft();
  }

  void updateTariffActivity(String val) {
    state = state.copyWith(tariffActivity: val);
    _saveDraft();
  }

  void updateGeocode(String val) {
    state = state.copyWith(geocode: val);
    _saveDraft();
  }

  void updateFindings(String val) {
    state = state.copyWith(findings: val);
    _saveDraft();
  }

  void updateInitialReadings(String val) {
    state = state.copyWith(initialReadings: val);
    _saveDraft();
  }

  void updateMeterId(String val) {
    state = state.copyWith(meterId: val);
    _saveDraft();
  }

  void updateSpnNumber(String val) {
    state = state.copyWith(spnNumber: val);
    _saveDraft();
  }

  void updateMeterBrand(String val) {
    state = state.copyWith(meterBrand: val);
    _saveDraft();
  }

  void updateMeterRating(String val) {
    state = state.copyWith(meterRating: val);
    _saveDraft();
  }

  void updateMeterPhase(String val) {
    state = state.copyWith(meterPhase: val);
    _saveDraft();
  }

  void updateMeteringType(String val) {
    state = state.copyWith(meteringType: val);
    _saveDraft();
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(isLocationLoading: true);
    final service = ref.read(deviceServiceProvider);
    final pos = await service.getCurrentLocation();
    if (pos != null) {
      state = state.copyWith(
        gpsCoordinates:
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        isLocationLoading: false,
      );
      _saveDraft();
    } else {
      state = state.copyWith(isLocationLoading: false);
    }
  }

  Future<void> simulateQrScan() async {
    state = state.copyWith(isLocationLoading: true);
    await Future.delayed(const Duration(seconds: 1));
    final randomId =
        'MET-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-QR';
    state = state.copyWith(meterId: randomId, isLocationLoading: false);
    _saveDraft();
  }

  Future<bool> captureImage() async {
    if (state.capturedImagePaths.length >= 5) {
      return false;
    }
    final service = ref.read(deviceServiceProvider);
    final res = await service.pickImage(ImageSource.camera);
    if (res != null) {
      state = state.copyWith(
        capturedImagePaths: [...state.capturedImagePaths, res],
      );
      _saveDraft();
      return true;
    }
    return false;
  }

  void removeImage(int index) {
    final newList = List<String>.from(state.capturedImagePaths);
    newList.removeAt(index);
    state = state.copyWith(capturedImagePaths: newList);
    _saveDraft();
  }

  Future<void> captureVideo() async {
    final service = ref.read(deviceServiceProvider);
    final res = await service.pickVideo(ImageSource.camera);
    if (res != null) {
      state = state.copyWith(capturedVideoPath: res);
      _saveDraft();
    }
  }

  void removeVideo() {
    state = state.copyWith(capturedVideoPath: null);
    _saveDraft();
  }

  void updateEstimatedLoad(int watts) {
    state = state.copyWith(estimatedLoadWatts: watts);
    _saveDraft();
  }

  void nextStep() {
    if (state.currentStep == 0 && !state.isStep1Valid) {
      return;
    }
    if (state.currentStep == 1 && !state.isStep2Valid) {
      return;
    }

    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _saveDraft();
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      _saveDraft();
    }
  }

  Future<Map<String, dynamic>?> uploadMediaToDrive() async {
    state = state.copyWith(isUploading: true);
    try {
      final driveService = ref.read(googleDriveServiceProvider);

      List<String> imageUrls = [];
      String? videoUrl;

      // 1. Upload captured images
      for (var i = 0; i < state.capturedImagePaths.length; i++) {
        final path = state.capturedImagePaths[i];
        final url = await driveService.uploadFile(
          file: io.File(path),
          fileName: 'meter_${state.meterId}_img_$i.jpg',
        );
        if (url != null) {
          imageUrls.add(url);
        }
      }

      // 2. Upload captured video if available
      if (state.capturedVideoPath != null) {
        videoUrl = await driveService.uploadFile(
          file: io.File(state.capturedVideoPath!),
          fileName: 'meter_${state.meterId}_video.mp4',
        );
      }

      state = state.copyWith(isUploading: false);

      return {'imageUrls': imageUrls, 'videoUrl': videoUrl};
    } catch (e) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }
}

final addMeterProvider = NotifierProvider<AddMeterNotifier, AddMeterState>(
  AddMeterNotifier.new,
);
