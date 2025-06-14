import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;
  static const int inputSize = 224;
  static const List<String> labels = ['Matang', 'Mentah', 'Belum Matang'];

  bool get isModelLoaded => _interpreter != null;

  /// Memuat model TFLite dari assets
  Future<void> loadModel() async {
    try {
      // Load model dari assets
      _interpreter =
          await Interpreter.fromAsset('assets/model/model_tomat.tflite');

      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  /// Melakukan prediksi pada gambar
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      // Baca dan preprocess gambar
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Unable to decode image');
      }

      // Preprocessing: resize dan normalize
      final preprocessedImage = _preprocessImage(image);

      // Persiapkan input dan output tensor
      final input = [preprocessedImage];
      final output = [List.filled(labels.length, 0.0)];

      // Jalankan inferensi
      _interpreter!.run(input, output);

      // Process hasil prediksi
      final predictions = output[0] as List<double>;
      final result = _processOutput(predictions);

      return result;
    } catch (e) {
      print('Error during prediction: $e');
      throw Exception('Prediction failed: $e');
    }
  }

  /// Preprocessing gambar: resize ke 224x224 dan normalize
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize gambar ke ukuran input model (224x224)
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Konversi ke format tensor [1, 224, 224, 3]
    final imageMatrix = List.generate(
      1,
      (index) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List.generate(3, (c) {
            final pixel = resizedImage.getPixel(x, y);
            double value;

            // Extract RGB values menggunakan pixel properties
            switch (c) {
              case 0:
                value = pixel.r.toDouble(); // Red channel
                break;
              case 1:
                value = pixel.g.toDouble(); // Green channel
                break;
              case 2:
                value = pixel.b.toDouble(); // Blue channel
                break;
              default:
                value = 0.0;
            }

            // Normalize pixel values to [0, 1]
            return value / 255.0;
          }),
        ),
      ),
    );

    return imageMatrix;
  }

  /// Memproses output model dan mengembalikan label dengan confidence tertinggi
  Map<String, dynamic> _processOutput(List<double> predictions) {
    // Cari index dengan confidence tertinggi
    double maxConfidence = 0.0;
    int maxIndex = 0;

    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] > maxConfidence) {
        maxConfidence = predictions[i];
        maxIndex = i;
      }
    }

    // Pastikan index tidak melebihi jumlah label
    if (maxIndex >= labels.length) {
      maxIndex = 0;
      maxConfidence = 0.0;
    }

    return {
      'label': labels[maxIndex],
      'confidence': maxConfidence,
      'index': maxIndex,
      'all_predictions': Map.fromIterables(
        labels,
        predictions.take(labels.length),
      ),
    };
  }

  /// Mendapatkan informasi detail semua prediksi
  Future<List<Map<String, dynamic>>> getAllPredictions(File imageFile) async {
    final result = await predict(imageFile);
    final allPredictions = result['all_predictions'] as Map<String, double>;

    return allPredictions.entries
        .map((entry) => {
              'label': entry.key,
              'confidence': entry.value,
            })
        .toList()
      ..sort((a, b) => ((b['confidence'] ?? 0.0) as double)
          .compareTo((a['confidence'] ?? 0.0) as double));
  }

  /// Membersihkan resource
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
