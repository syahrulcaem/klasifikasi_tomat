import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String label;
  final double confidence;
  final bool isLoading;

  const ResultCard({
    Key? key,
    required this.label,
    required this.confidence,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }

    return _buildResultCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF64B5F6),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Menganalisis Gambar...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI sedang memproses gambar tomat Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final resultInfo = _getResultInfo(label);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: resultInfo['colors'],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: resultInfo['colors'][0].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon dan Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  resultInfo['icon'],
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hasil Klasifikasi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    resultInfo['displayName'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Confidence Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tingkat Kepercayaan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status Message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  resultInfo['statusIcon'],
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultInfo['statusMessage'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getResultInfo(String classification) {
    switch (classification.toLowerCase()) {
      case 'matang':
        return {
          'displayName': 'Tomat Matang 🍅',
          'colors': [const Color(0xFFD32F2F), const Color(0xFFE53935)],
          'icon': Icons.check_circle,
          'statusIcon': Icons.thumb_up,
          'statusMessage':
              'Sempurna! Tomat siap untuk dikonsumsi langsung atau dijadikan salad.',
        };

      case 'mentah':
        return {
          'displayName': 'Tomat Mentah 🟢',
          'colors': [const Color(0xFF388E3C), const Color(0xFF43A047)],
          'icon': Icons.schedule,
          'statusIcon': Icons.restaurant,
          'statusMessage':
              'Cocok untuk dimasak! Ideal untuk tumisan, sup, atau sauce.',
        };

      case 'belum matang':
      case 'belum_matang':
        return {
          'displayName': 'Belum Matang 🟡',
          'colors': [const Color(0xFFF57C00), const Color(0xFFFF9800)],
          'icon': Icons.hourglass_empty,
          'statusIcon': Icons.access_time,
          'statusMessage':
              'Simpan di suhu ruang beberapa hari untuk mempercepat pematangan.',
        };

      case 'bukan tomat':
      case 'bukan_tomat':
        return {
          'displayName': 'Bukan Tomat ❌',
          'colors': [const Color(0xFF757575), const Color(0xFF9E9E9E)],
          'icon': Icons.error_outline,
          'statusIcon': Icons.info,
          'statusMessage':
              'Objek yang terdeteksi bukan tomat. Coba ambil foto tomat yang jelas.',
        };

      default:
        return {
          'displayName': 'Tidak Dikenal',
          'colors': [const Color(0xFF757575), const Color(0xFF9E9E9E)],
          'icon': Icons.help_outline,
          'statusIcon': Icons.warning,
          'statusMessage':
              'Hasil tidak dapat diidentifikasi. Silakan coba lagi.',
        };
    }
  }
}
