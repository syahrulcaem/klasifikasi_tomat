import 'package:flutter/material.dart';
import 'dart:io';
import '../services/image_helper.dart';
import '../services/classifier_service.dart';
import '../widgets/result_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  String _predictionResult = '';
  double _confidence = 0.0;
  bool _isLoading = false;

  final ClassifierService _classifierService = ClassifierService();

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    try {
      await _classifierService.loadModel();
      print('Classifier initialized successfully');
    } catch (e) {
      print('Error initializing classifier: $e');
      _showErrorSnackBar('Gagal memuat model: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromCamera() async {
    setState(() => _isLoading = true);

    try {
      final image = await ImageHelper.captureFromCamera();
      if (image != null) {
        await _classifyImage(image);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      _showErrorSnackBar('Gagal mengambil gambar dari kamera');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final image = await ImageHelper.pickFromGallery();
      if (image != null) {
        await _classifyImage(image);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      _showErrorSnackBar('Gagal mengambil gambar dari galeri');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _classifyImage(File image) async {
    try {
      final result = await _classifierService.predict(image);

      setState(() {
        _selectedImage = image;
        _predictionResult = result['label'] ?? 'Tidak diketahui';
        _confidence = result['confidence'] ?? 0.0;
      });
    } catch (e) {
      print('Error classifying image: $e');
      setState(() {
        _selectedImage = image;
        _predictionResult = 'Error';
        _confidence = 0.0;
      });
      _showErrorSnackBar('Gagal melakukan klasifikasi: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _resetSelection() {
    setState(() {
      _selectedImage = null;
      _predictionResult = '';
      _confidence = 0.0;
    });
  }

  // Modern AppBar dengan gradient
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: const Text(
        '🍅 Klasifikasi Tomat',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF8BC34A),
              Color(0xFFCDDC39),
            ],
          ),
        ),
      ),
      elevation: 0,
      centerTitle: true,
      actions: [
        if (_selectedImage != null)
          IconButton(
            onPressed: _resetSelection,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset',
          ),
      ],
    );
  }

  // Header card dengan gradient
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF81C784),
            Color(0xFFAED581),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.agriculture,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Deteksi Kematangan Tomat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klasifikasi otomatis menggunakan AI untuk menentukan tingkat kematangan tomat Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Image preview card dengan design modern
  Widget _buildImagePreviewCard() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF1F8E9),
                Color(0xFFE8F5E8),
              ],
            ),
          ),
          child: _selectedImage == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate,
                        size: 60,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ambil atau Pilih Foto Tomat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload gambar tomat untuk analisis kematangan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Action buttons dengan design modern
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImageFromCamera,
              icon: const Icon(Icons.camera_alt, size: 24),
              label: const Text(
                'Kamera',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImageFromGallery,
              icon: const Icon(Icons.photo_library, size: 24),
              label: const Text(
                'Galeri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Nutrition card berdasarkan hasil klasifikasi
  Widget _buildNutritionCard() {
    Map<String, dynamic> nutritionInfo = _getNutritionInfo(_predictionResult);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: nutritionInfo['colors'],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: nutritionInfo['colors'][0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                nutritionInfo['icon'],
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                nutritionInfo['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nutritionInfo['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kandungan Nutrisi:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...nutritionInfo['nutrients']
              .map<Widget>((nutrient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          nutrient,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  // Usage guide card
  Widget _buildUsageGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cara Penggunaan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
              '1', 'Pastikan tomat terlihat jelas dan fokus', Icons.visibility),
          _buildTipItem('2', 'Gunakan pencahayaan yang cukup', Icons.wb_sunny),
          _buildTipItem(
              '3', 'Ambil foto dari jarak 15-30 cm', Icons.straighten),
          _buildTipItem(
              '4', 'Hindari bayangan pada tomat', Icons.highlight_off),
        ],
      ),
    );
  }

  // General tomato info card
  Widget _buildTomatoInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7043),
            Color(0xFFFF8A65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Tentang Tomat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tomat adalah buah yang kaya akan vitamin C, likopen, dan antioksidan. '
            'Tingkat kematangan tomat mempengaruhi rasa, tekstur, dan kandungan nutrisinya.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manfaat Tomat:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            'Sumber vitamin C dan K tinggi',
            'Mengandung likopen untuk antioksidan',
            'Baik untuk kesehatan jantung',
            'Membantu menjaga kesehatan kulit'
          ]
              .map((benefit) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            benefit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTipItem(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFF2196F3), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNutritionInfo(String classification) {
    switch (classification.toLowerCase()) {
      case 'matang':
        return {
          'title': 'Tomat Matang 🍅',
          'colors': [const Color(0xFFD32F2F), const Color(0xFFE53935)],
          'icon': Icons.favorite,
          'description':
              'Tomat matang memiliki kandungan likopen tertinggi dan rasa yang optimal. '
                  'Sangat baik untuk dikonsumsi langsung atau dalam salad.',
          'nutrients': [
            'Likopen: 3.0-5.0 mg (antioksidan kuat)',
            'Vitamin C: 23 mg (25% kebutuhan harian)',
            'Kalium: 237 mg (baik untuk jantung)',
            'Folat: 15 mcg (untuk sel darah merah)',
            'Vitamin K: 7.9 mcg (untuk tulang)',
          ]
        };
      case 'mentah':
        return {
          'title': 'Tomat Mentah 🟢',
          'colors': [const Color(0xFF388E3C), const Color(0xFF43A047)],
          'icon': Icons.eco,
          'description':
              'Tomat mentah cocok untuk dimasak, memiliki tekstur yang lebih keras '
                  'dan rasa yang sedikit asam. Baik untuk tumisan dan sup.',
          'nutrients': [
            'Vitamin C: 20 mg (sedikit lebih rendah)',
            'Likopen: 1.0-2.0 mg (akan meningkat saat matang)',
            'Kalsium: 10 mg (untuk tulang)',
            'Magnesium: 11 mg (untuk otot)',
            'Serat: 1.2 g (untuk pencernaan)',
          ]
        };
      case 'belum matang':
        return {
          'title': 'Tomat Belum Matang 🟡',
          'colors': [const Color(0xFFF57C00), const Color(0xFFFF9800)],
          'icon': Icons.schedule,
          'description':
              'Tomat belum matang sebaiknya disimpan dalam suhu ruang untuk proses pematangan. '
                  'Dapat digunakan untuk pickle atau tumisan tertentu.',
          'nutrients': [
            'Vitamin C: 15-18 mg (masih dalam proses pembentukan)',
            'Karbohidrat: 3.9 g (energi)',
            'Protein: 0.9 g (untuk pertumbuhan)',
            'Air: 94% (hidrasi)',
            'Serat: 1.2 g (pencernaan)',
          ]
        };
      case 'bukan tomat':
        return {
          'title': 'Bukan Tomat ❌',
          'colors': [const Color(0xFF757575), const Color(0xFF9E9E9E)],
          'icon': Icons.error_outline,
          'description':
              'Objek yang terdeteksi bukan tomat. Silakan coba lagi dengan gambar tomat yang jelas.',
          'nutrients': [
            'Pastikan objek adalah tomat',
            'Coba ambil foto dengan pencahayaan lebih baik',
            'Posisikan tomat di tengah frame',
            'Hindari objek lain dalam foto',
          ]
        };
      default:
        return {
          'title': 'Hasil Tidak Dikenal',
          'colors': [const Color(0xFF757575), const Color(0xFF9E9E9E)],
          'icon': Icons.help_outline,
          'description': 'Hasil klasifikasi tidak dapat diidentifikasi.',
          'nutrients': ['Silakan coba lagi']
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: _buildModernAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header dengan gradient
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Image Preview Card
            _buildImagePreviewCard(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 24),

            // Result Card
            if (_predictionResult.isNotEmpty || _isLoading)
              ResultCard(
                label: _predictionResult,
                confidence: _confidence,
                isLoading: _isLoading,
              ),

            // Nutrition Info Card - tampilkan berdasarkan hasil
            if (_predictionResult.isNotEmpty && !_isLoading)
              _buildNutritionCard(),

            // Usage Guide
            if (_selectedImage == null && !_isLoading) _buildUsageGuideCard(),

            // General Tomato Info
            if (_selectedImage == null && !_isLoading) _buildTomatoInfoCard(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }
}
