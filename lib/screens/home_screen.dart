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

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: const Text(
        '🍅 TomatIQ',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: _buildModernAppBar(),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      _buildImagePreviewCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      if (_predictionResult.isNotEmpty || _isLoading)
                        ResultCard(
                          label: _predictionResult,
                          confidence: _confidence,
                          isLoading: _isLoading,
                        ),

                      if (_predictionResult.isNotEmpty && !_isLoading)
                        _buildNutritionCard(),

                      if (_selectedImage == null && !_isLoading) ...[
                        const SizedBox(height: 24),
                        _buildUsageGuideCard(),
                        const SizedBox(height: 24),
                        _buildTomatoInfoCard(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF81C784), Color(0xFFAED581)],
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
          const Icon(Icons.agriculture, size: 40, color: Colors.white),
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
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

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
              colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E8)],
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt, size: 24),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickImageFromGallery,
            icon: const Icon(Icons.photo_library, size: 24),
            label: const Text('Galeri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
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
          _buildTipItem('1', 'Pastikan tomat terlihat jelas dan fokus', Icons.visibility),
          _buildTipItem('2', 'Gunakan pencahayaan yang cukup', Icons.wb_sunny),
          _buildTipItem('3', 'Ambil foto dari jarak 15-30 cm', Icons.straighten),
          _buildTipItem('4', 'Hindari bayangan pada tomat', Icons.highlight_off),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    // Fungsi ini tetap kamu pakai dari sebelumnya (_getNutritionInfo)
    final info = _getNutritionInfo(_predictionResult);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: info['colors'],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: info['colors'][0].withOpacity(0.3),
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
              Icon(info['icon'], color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                info['title'],
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
            info['description'],
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
          ...info['nutrients'].map<Widget>((nutrient) {
            return Padding(
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
                      nutrient,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTomatoInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7043), Color(0xFFFF8A65)],
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
        children: const [
          Row(
            children: [
              Icon(Icons.info, color: Colors.white, size: 28),
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
          SizedBox(height: 16),
          Text(
            'Tomat adalah buah yang kaya akan vitamin C, likopen, dan antioksidan. '
            'Tingkat kematangan tomat mempengaruhi rasa, tekstur, dan kandungan nutrisinya.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNutritionInfo(String label) {
   switch (label.toLowerCase()) {
    case 'matang':
      return {
        'title': 'Tomat Matang 🍅',
        'description': 'Tomat matang memiliki rasa manis, kaya likopen, dan siap dikonsumsi atau dimasak.',
        'icon': Icons.check_circle,
        'colors': [Colors.red.shade400, Colors.red.shade700],
        'nutrients': ['Vitamin C', 'Likopen', 'Antioksidan tinggi', 'Kalium'],
      };
    case 'setengah matang':
      return {
        'title': 'Tomat Setengah Matang 🟠',
        'description': 'Tomat ini masih dalam proses matang. Cocok untuk disimpan beberapa hari sebelum dikonsumsi.',
        'icon': Icons.hourglass_top,
        'colors': [Colors.orange.shade300, Colors.orange.shade700],
        'nutrients': ['Vitamin A', 'Vitamin C', 'Sedikit likopen'],
      };
    case 'mentah':
      return {
        'title': 'Tomat Mentah 🟢',
        'description': 'Tomat mentah cenderung keras dan asam. Bisa digunakan untuk acar atau disimpan untuk pematangan lebih lanjut.',
        'icon': Icons.close,
        'colors': [Colors.green.shade400, Colors.green.shade700],
        'nutrients': ['Serat', 'Vitamin K', 'Klorofil'],
      };
    default:
      return {
        'title': 'Informasi Tidak Ditemukan',
        'description': 'Jenis tomat tidak dikenali. Coba unggah gambar lain.',
        'icon': Icons.warning,
        'colors': [Colors.grey.shade400, Colors.grey.shade600],
        'nutrients': ['-'],
      };
  }
}

  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }
}
