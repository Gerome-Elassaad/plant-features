import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/features/diagnosis/providers/diagnosis_provider.dart';
import 'package:aspargo/features/diagnosis/widgets/image_selection_card.dart';
import 'package:aspargo/features/diagnosis/widgets/loading_overlay.dart';
import 'package:aspargo/features/diagnosis/widgets/diagnose_result_view.dart'; // Corrected path

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Diagnosis'),
        actions: [
          Consumer<DiagnosisProvider>(
            builder: (context, provider, _) {
              if (provider.diagnosisResult != null) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    provider.reset();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<DiagnosisProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              if (provider.diagnosisResult != null)
                DiagnosisResultView(result: provider.diagnosisResult!)
              else
                _buildMainContent(context, provider),
              
              if (provider.isLoading)
                LoadingOverlay(
                  message: provider.getStateMessage(),
                  progress: provider.state == DiagnosisState.uploading
                      ? provider.uploadProgress
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, DiagnosisProvider provider) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.infoColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: AppTheme.headlineMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Take or select a clear photo of your plant\n'
                        '2. Make sure the plant is well-lit and in focus\n'
                        '3. Include leaves or affected areas for disease detection\n'
                        '4. Get instant diagnosis and care recommendations',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Image selection
            if (provider.selectedImage == null)
              _buildImageSelection(context, provider)
            else
              _buildSelectedImage(context, provider),
            
            const SizedBox(height: 24),
            
            // Analyze button
            if (provider.selectedImage != null)
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: ElevatedButton.icon(
                  onPressed: provider.canAnalyze
                      ? () => provider.analyzePlant()
                      : null,
                  icon: const Icon(Icons.search),
                  label: const Text('Analyze Plant'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: AppTheme.labelLarge,
                  ),
                ),
              ),
            
            // Error message
            if (provider.errorMessage != null)
              FadeIn(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Error',
                              style: AppTheme.headlineSmall.copyWith(
                                color: AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.errorMessage!,
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => provider.clearError(),
                        color: AppTheme.errorColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelection(BuildContext context, DiagnosisProvider provider) {
    return Column(
      children: [
        FadeInLeft(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 200),
          child: ImageSelectionCard(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            description: 'Use your camera to capture a plant',
            onTap: () => provider.selectImage(ImageSource.camera),
          ),
        ),
        const SizedBox(height: 16),
        FadeInRight(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 400),
          child: ImageSelectionCard(
            icon: Icons.photo_library,
            title: 'Choose from Gallery',
            description: 'Select an existing photo',
            onTap: () => provider.selectImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImage(BuildContext context, DiagnosisProvider provider) {
    return FadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selected Image',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    provider.selectedImage!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onPressed: () => provider.reset(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => provider.reset(),
            icon: const Icon(Icons.image),
            label: const Text('Choose Different Image'),
          ),
        ],
      ),
    );
  }
}
