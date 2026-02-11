import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion Bluetooth'),
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetooth, child) {
          return Column(
            children: [
              // État de connexion
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: bluetooth.isConnected
                        ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                        : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      bluetooth.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bluetooth.isConnected ? 'Connecté' : 'Non connecté',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (bluetooth.connectedDevice != null)
                            Text(
                              bluetooth.connectedDevice!.platformName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (bluetooth.isConnected)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          bluetooth.disconnect();
                        },
                      ),
                  ],
                ),
              ),

              // Bouton de scan
              if (!bluetooth.isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: bluetooth.isScanning
                          ? null
                          : () {
                              bluetooth.startScan();
                            },
                      icon: bluetooth.isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        bluetooth.isScanning ? 'Recherche...' : 'Scanner les appareils',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Liste des appareils découverts
              if (!bluetooth.isConnected)
                Expanded(
                  child: bluetooth.scanResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun appareil trouvé',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Appuie sur "Scanner" pour chercher',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: bluetooth.scanResults.length,
                          itemBuilder: (context, index) {
                            final result = bluetooth.scanResults[index];
                            final device = result.device;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667eea).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.bluetooth,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                                title: Text(
                                  device.platformName.isEmpty
                                      ? 'Appareil inconnu'
                                      : device.platformName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  device.remoteId.toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: result.rssi != null
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getSignalIcon(result.rssi!),
                                            color: _getSignalColor(result.rssi!),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${result.rssi} dBm',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () async {
                                  // Arrêter le scan
                                  await bluetooth.stopScan();

                                  // Afficher un dialogue de connexion
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Connexion...'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text('Connexion à ${device.platformName}'),
                                        ],
                                      ),
                                    ),
                                  );

                                  // Tenter la connexion
                                  bool success = await bluetooth.connectToDevice(device);

                                  // Fermer le dialogue
                                  Navigator.of(context).pop();

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Connecté avec succès!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('❌ Échec de la connexion'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),

              // Informations de connexion
              if (bluetooth.isConnected)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          'Données en temps réel',
                          [
                            _buildInfoRow('Angle', '${bluetooth.currentAngle.toStringAsFixed(1)}°'),
                            _buildInfoRow('Répétitions', '${bluetooth.currentReps}'),
                            _buildInfoRow('Statut', bluetooth.movementStatus),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              bluetooth.calibrate();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚙️ Calibration lancée...'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Calibrer le capteur'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: const Color(0xFFFFA726),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi > -60) return Icons.signal_cellular_4_bar;
    if (rssi > -70) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -70) return Colors.orange;
    return Colors.red;
  }
}
