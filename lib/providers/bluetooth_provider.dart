import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  BluetoothCharacteristic? _commandCharacteristic;
  
  bool _isScanning = false;
  bool _isConnected = false;
  List<ScanResult> _scanResults = [];
  
  // Données en temps réel
  double _currentAngle = 0.0;
  int _currentReps = 0;
  bool _isMovingUp = false;
  String _movementStatus = 'En attente';
  
  // UUIDs pour le service BLE (à modifier selon ton firmware ESP32)
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String DATA_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String COMMAND_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  
  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  double get currentAngle => _currentAngle;
  int get currentReps => _currentReps;
  bool get isMovingUp => _isMovingUp;
  String get movementStatus => _movementStatus;
  
  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;
  
  BluetoothProvider() {
    _initBluetooth();
  }
  
  Future<void> _initBluetooth() async {
    // Vérifier si le Bluetooth est supporté
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint("Bluetooth non supporté sur cet appareil");
      return;
    }
    
    // Demander les permissions
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      
      if (statuses.values.any((status) => !status.isGranted)) {
        debugPrint("Certaines permissions Bluetooth ne sont pas accordées");
      }
    }
  }
  
  // Scanner les appareils BLE
  Future<void> startScan() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();
    
    try {
      // Démarrer le scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
      
      // Écouter les résultats
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();
        notifyListeners();
      });
      
      // Arrêter automatiquement après le timeout
      await Future.delayed(const Duration(seconds: 10));
      await stopScan();
    } catch (e) {
      debugPrint("Erreur lors du scan: $e");
      _isScanning = false;
      notifyListeners();
    }
  }
  
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }
  
  // Connecter à un appareil
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint("Connexion à ${device.platformName}...");
      
      // Se connecter
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // Découvrir les services
      List<BluetoothService> services = await device.discoverServices();
      
      // Trouver notre service et nos caractéristiques
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            
            if (charUuid == DATA_CHARACTERISTIC_UUID.toLowerCase()) {
              _dataCharacteristic = characteristic;
              // S'abonner aux notifications
              await characteristic.setNotifyValue(true);
              _subscribeToData();
            } else if (charUuid == COMMAND_CHARACTERISTIC_UUID.toLowerCase()) {
              _commandCharacteristic = characteristic;
            }
          }
        }
      }
      
      if (_dataCharacteristic == null || _commandCharacteristic == null) {
        debugPrint("Caractéristiques non trouvées");
        await disconnect();
        return false;
      }
      
      _isConnected = true;
      notifyListeners();
      debugPrint("Connecté avec succès!");
      return true;
      
    } catch (e) {
      debugPrint("Erreur de connexion: $e");
      await disconnect();
      return false;
    }
  }
  
  // S'abonner aux données en temps réel
  void _subscribeToData() {
    if (_dataCharacteristic == null) return;
    
    _dataSubscription = _dataCharacteristic!.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        try {
          // Décoder les données JSON envoyées par l'ESP32
          String jsonString = utf8.decode(value);
          Map<String, dynamic> data = jsonDecode(jsonString);
          
          _currentAngle = data['angle']?.toDouble() ?? 0.0;
          _currentReps = data['reps'] ?? 0;
          _isMovingUp = data['isMovingUp'] ?? false;
          _movementStatus = data['status'] ?? 'En attente';
          
          notifyListeners();
        } catch (e) {
          debugPrint("Erreur décodage données: $e");
        }
      }
    });
  }
  
  // Envoyer une commande à l'ESP32
  Future<void> sendCommand(String command, [Map<String, dynamic>? params]) async {
    if (_commandCharacteristic == null || !_isConnected) {
      debugPrint("Pas connecté ou caractéristique non disponible");
      return;
    }
    
    try {
      Map<String, dynamic> commandData = {
        'cmd': command,
        if (params != null) 'params': params,
      };
      
      String jsonString = jsonEncode(commandData);
      List<int> bytes = utf8.encode(jsonString);
      
      await _commandCharacteristic!.write(bytes, withoutResponse: false);
      debugPrint("Commande envoyée: $command");
    } catch (e) {
      debugPrint("Erreur envoi commande: $e");
    }
  }
  
  // Commandes spécifiques
  Future<void> startWorkout(String exerciseId) async {
    await sendCommand('START', {'exercise': exerciseId});
  }
  
  Future<void> endSet() async {
    await sendCommand('END_SET');
  }
  
  Future<void> endWorkout() async {
    await sendCommand('END_WORKOUT');
  }
  
  Future<void> calibrate() async {
    await sendCommand('CALIBRATE');
  }
  
  Future<void> setExercise(String exerciseId) async {
    await sendCommand('SET_EXERCISE', {'exercise': exerciseId});
  }
  
  // Déconnexion
  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      
      _connectedDevice = null;
      _dataCharacteristic = null;
      _commandCharacteristic = null;
      _isConnected = false;
      
      // Réinitialiser les données
      _currentAngle = 0.0;
      _currentReps = 0;
      _isMovingUp = false;
      _movementStatus = 'En attente';
      
      notifyListeners();
      debugPrint("Déconnecté");
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion: $e");
    }
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
