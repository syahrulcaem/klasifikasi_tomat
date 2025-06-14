import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;
  static const int inputSize = 150; // ✅ Ubah dari 170 ke 150
  static const List<String> labels = ['matang', 'mentah', 'belum matang'];

  bool get isModelLoaded => _interpreter != null;

  Future<void> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/model_tomat.tflite');
      print('Model TensorFlow Lite berhasil dimuat!');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) {
      throw Exception(
          'Model belum dimuat. Panggil loadModel() terlebih dahulu.');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Gagal decoding gambar');
      }

      // ❌ JANGAN pakai ini - struktur salah
      // final inputTensor = _preprocessImage(image);

      // ✅ PAKAI ini - struktur benar
      final inputTensor = await preprocessImage(imageFile);

      var output = [
        List<double>.filled(labels.length, 0.0)
      ]; // [[0.0, 0.0, 0.0, 0.0]]

      // Add this line before calling interpreter.run() to debug the input shape
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('Input data length: ${inputTensor.length}');
      print(
          'Input data shape: [${inputTensor.length}, ${inputTensor[0].length}, ${inputTensor[0][0].length}, ${inputTensor[0][0][0].length}]');

      _interpreter!.run(inputTensor, output);

      return _processOutput(output[0]);
    } catch (e) {
      print('Error during prediction: $e');
      throw Exception('Prediksi gagal: $e');
    }
  }

  /// 🔧 Konversi gambar ke tensor 4D: [1, 224, 224, 3]
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized =
        img.copyResize(image, width: 150, height: 150); // ✅ Ubah ke 150×150

    return List.generate(
        1,
        (batch) => List.generate(
            150,
            (y) => // ✅ Ubah ke 150
                List.generate(150, (x) {
                  final pixel = resized.getPixel(x, y);
                  return [
                    pixel.r.toDouble() / 255.0,
                    pixel.g.toDouble() / 255.0,
                    pixel.b.toDouble() / 255.0,
                  ];
                })));
  }

  // Add proper image preprocessing
  Future<List<List<List<List<double>>>>> preprocessImage(File imageFile) async {
    // Read and decode the image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Could not decode image');

    // Resize to 150x150 (expected input size)
    final resized = img.copyResize(image, width: 150, height: 150);

    // Convert to 4D tensor [1, 150, 150, 3]
    final input = List.generate(
        1,
        (batch) => List.generate(
            150,
            (y) => List.generate(150, (x) {
                  final pixel = resized.getPixel(x, y);
                  return [
                    pixel.r.toDouble() / 255.0,
                    pixel.g.toDouble() / 255.0,
                    pixel.b.toDouble() / 255.0,
                  ];
                })));

    print(
        'Preprocessed input shape: [${input.length}, ${input[0].length}, ${input[0][0].length}, ${input[0][0][0].length}]');
    return input;
  }

  Map<String, dynamic> _processOutput(List<double> predictions) {
    int maxIndex = 0;
    double maxConfidence = predictions[0];

    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > maxConfidence) {
        maxConfidence = predictions[i];
        maxIndex = i;
      }
    }

    // ✅ Jika confidence rendah, anggap "bukan tomat"
    String predictedLabel =
        maxConfidence < 0.8 ? 'bukan tomat' : labels[maxIndex];

    return {
      'label': predictedLabel,
      'confidence': maxConfidence,
    };
  }

  Future<List<Map<String, dynamic>>> getAllPredictions(File imageFile) async {
    final result = await predict(imageFile);
    final allPredictions = result['all_predictions'] as Map<String, double>;

    return allPredictions.entries
        .map((e) => {
              'label': e.key,
              'confidence': e.value,
            })
        .toList()
      ..sort((a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double));
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    print('Interpreter ditutup.');
  }
}
