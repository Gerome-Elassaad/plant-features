import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aspargo/core/services/api_service.dart';
import 'package:aspargo/core/constants/api_constants.dart';
import 'package:aspargo/core/exceptions/app_execptions.dart';
import 'package:aspargo/features/diagnosis/models/diagnosis_model.dart';
import 'package:aspargo/features/diagnosis/services/image_service.dart';

enum DiagnosisState {
  idle,
  selectingImage,
  compressingImage,
  uploading,
  analyzing,
  success,
  error
}

class DiagnosisProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final ImageService _imageService = ImageService();
  
  DiagnosisState _state = DiagnosisState.idle;
  DiagnosisState get state => _state;
  
  File? _selectedImage;
  File? get selectedImage => _selectedImage;
  
  DiagnosisResponse? _diagnosisResult;
  DiagnosisResponse? get diagnosisResult => _diagnosisResult;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;
  
  bool _similarImages = false; // Default value
  bool get similarImages => _similarImages;
  
  String _plantLanguage = 'en'; // Default value
  String get plantLanguage => _plantLanguage;
  
  List<String> _selectedModifiers = ['common_names', 'url'];
  List<String> get selectedModifiers => _selectedModifiers;
  
  void _setState(DiagnosisState newState) {
    _state = newState;
    notifyListeners();
  }
  
  void setModifiers(List<String> modifiers) {
    _selectedModifiers = modifiers;
    notifyListeners();
  }
  
  void setSimilarImages(bool value) {
    _similarImages = value;
    notifyListeners();
  }
  
  void setPlantLanguage(String languageCode) {
    _plantLanguage = languageCode;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void reset() {
    _state = DiagnosisState.idle;
    _selectedImage = null;
    _diagnosisResult = null;
    _errorMessage = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }
  
  Future<void> selectImage(ImageSource source) async {
    try {
      _setState(DiagnosisState.selectingImage);
      clearError();
      
      final XFile? pickedFile = await _imageService.pickImage(source);
      
      if (pickedFile == null) {
        _setState(DiagnosisState.idle);
        return;
      }
      
      _selectedImage = File(pickedFile.path);
      _setState(DiagnosisState.idle);
      
    } catch (e) {
      _errorMessage = 'Failed to select image: ${e.toString()}';
      _setState(DiagnosisState.error);
    }
  }
  
  Future<void> analyzePlant() async {
    if (_selectedImage == null) {
      _errorMessage = 'Please select an image first';
      _setState(DiagnosisState.error);
      return;
    }
    
    try {
      // Compress image
      _setState(DiagnosisState.compressingImage);
      final compressedImage = await _imageService.compressImage(_selectedImage!);
      
      // Check file size
      final fileSize = await compressedImage.length();
      if (fileSize > ApiConstants.maxFileSize) {
        throw FileException('Image file is too large. Maximum size is 10MB.');
      }
      
      // Prepare form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          compressedImage.path,
          filename: 'plant_image.jpg',
        ),
        'plant_details': _selectedModifiers,
        'similar_images': _similarImages,
        'plant_language': _plantLanguage,
      });
      
      // Upload and analyze
      _setState(DiagnosisState.uploading);
      _uploadProgress = 0.0;
      
      final response = await _apiService.postFormData<Map<String, dynamic>>(
        ApiConstants.diagnosis,
        formData: formData,
        onSendProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      
      _setState(DiagnosisState.analyzing);
      
      // Parse response
      _diagnosisResult = DiagnosisResponse.fromJson(response);
      
      if (_diagnosisResult!.success) {
        _setState(DiagnosisState.success);
      } else {
        throw AppException('Analysis failed. Please try again.');
      }
      
    } on FileException catch (e) {
      _errorMessage = e.message;
      _setState(DiagnosisState.error);
    } on NetworkException catch (e) {
      _errorMessage = 'Network error: ${e.message}';
      _setState(DiagnosisState.error);
    } on ServerException catch (e) {
      _errorMessage = 'Server error: ${e.message}';
      _setState(DiagnosisState.error);
    } on RateLimitException {
      _errorMessage = 'Too many requests. Please try again later.';
      _setState(DiagnosisState.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _setState(DiagnosisState.error);
    }
  }
  
  Future<void> retryAnalysis() async {
    if (_selectedImage != null) {
      await analyzePlant();
    }
  }
  
  String getStateMessage() {
    switch (_state) {
      case DiagnosisState.idle:
        return 'Ready to analyze';
      case DiagnosisState.selectingImage:
        return 'Selecting image...';
      case DiagnosisState.compressingImage:
        return 'Compressing image...';
      case DiagnosisState.uploading:
        return 'Uploading image... ${(_uploadProgress * 100).toStringAsFixed(0)}%';
      case DiagnosisState.analyzing:
        return 'Analyzing plant...';
      case DiagnosisState.success:
        return 'Analysis complete!';
      case DiagnosisState.error:
        return _errorMessage ?? 'An error occurred';
    }
  }
  
  bool get canAnalyze => _selectedImage != null && _state == DiagnosisState.idle;
  
  bool get isLoading => 
      _state == DiagnosisState.selectingImage ||
      _state == DiagnosisState.compressingImage ||
      _state == DiagnosisState.uploading ||
      _state == DiagnosisState.analyzing;
}
