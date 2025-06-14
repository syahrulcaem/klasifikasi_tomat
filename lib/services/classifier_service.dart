import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;
  static const int inputSize = 224;
  static const List<String> labels = ['bukan_tomat', 'half_ripe', 'mature', 'unripe'];

  bool get isModelLoaded => _interpreter != null;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_tomat.tflite');
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
      throw Exception('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Gagal decoding gambar');
      }

      final inputTensor = _preprocessImage(image);

      var output = [List<double>.filled(labels.length, 0.0)]; // [[0.0, 0.0, 0.0, 0.0]]

      _interpreter!.run(inputTensor, output);

      return _processOutput(output[0]);
    } catch (e) {
      print('Error during prediction: $e');
      throw Exception('Prediksi gagal: $e');
    }
  }

  /// 🔧 Konversi gambar ke tensor 4D: [1, 224, 224, 3]
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    return [
      List.generate(inputSize, (y) =>
        List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0,
            pixel.g.toDouble() / 255.0,
            pixel.b.toDouble() / 255.0,
          ];
        }),
      )
    ];
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

    return {
      'label': labels[maxIndex],
      'confidence': maxConfidence,
      'index': maxIndex,
      'all_predictions': Map.fromIterables(labels, predictions),
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
      ..sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    print('Interpreter ditutup.');
  }
}
