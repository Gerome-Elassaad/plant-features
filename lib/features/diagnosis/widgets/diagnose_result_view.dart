// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/features/diagnosis/models/diagnosis_model.dart';

class DiagnosisResultView extends StatelessWidget {
  final DiagnosisResponse result;
  
  const DiagnosisResultView({
    super.key,
    required this.result,
  });
  
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final data = result.data;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Is Plant Check
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: _buildIsPlantCard(context, data),
            ),
            
            if (data.isPlant && data.suggestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              
              // Plant Identification
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Plant Identification',
                  style: AppTheme.headlineLarge,
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...data.suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;
                return FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: 400 + (index * 100)),
                  child: _buildPlantSuggestionCard(context, suggestion, index == 0),
                );
              }),
              
              // Health Assessment
              if (data.healthAssessment != null) ...[
                const SizedBox(height: 20),
                FadeInLeft(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 600),
                  child: Text(
                    'Health Assessment',
                    style: AppTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInRight(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 700),
                  child: _buildHealthAssessmentCard(context, data.healthAssessment!),
                ),
              ],
              
              // Disease Suggestions
              if (data.diseaseSuggestions.isNotEmpty) ...[
                const SizedBox(height: 20),
                FadeInLeft(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 800),
                  child: Text(
                    'Possible Diseases',
                    style: AppTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.diseaseSuggestions.map((disease) {
                  return FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 900),
                    child: _buildDiseaseCard(context, disease),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildIsPlantCard(BuildContext context, DiagnosisData data) {
    final theme = Theme.of(context);
    final isPlant = data.isPlant;
    final confidence = (data.isPlantProbability * 100).toStringAsFixed(1);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isPlant ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: isPlant ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              isPlant ? 'This is a plant!' : 'Not a plant',
              style: AppTheme.headlineLarge.copyWith(
                color: isPlant ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: $confidence%',
              style: AppTheme.bodyLarge,
            ),
            if (!isPlant) ...[
              const SizedBox(height: 16),
              Text(
                'Please try again with a clear photo of a plant',
                style: AppTheme.bodyMedium.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlantSuggestionCard(BuildContext context, PlantSuggestion suggestion, bool isTopResult) {
    final theme = Theme.of(context);
    final confidence = (suggestion.probability * 100).toStringAsFixed(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopResult ? 4 : 2,
      child: Container(
        decoration: isTopResult
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTopResult)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TOP MATCH',
                              style: AppTheme.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          suggestion.plantName,
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.plantDetails.scientificName,
                          style: AppTheme.bodyMedium.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(suggestion.probability).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getConfidenceColor(suggestion.probability),
                      ),
                    ),
                    child: Text(
                      '$confidence%',
                      style: AppTheme.labelMedium.copyWith(
                        color: _getConfidenceColor(suggestion.probability),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (suggestion.plantDetails.commonNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: suggestion.plantDetails.commonNames
                      .take(3)
                      .map((name) => Chip(
                            label: Text(
                              name,
                              style: AppTheme.labelSmall,
                            ),
                            backgroundColor: theme.chipTheme.backgroundColor,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ))
                      .toList(),
                ),
              ],
              
              if (suggestion.plantDetails.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  suggestion.plantDetails.description!,
                  style: AppTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (suggestion.plantDetails.url != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _launchUrl(suggestion.plantDetails.url!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Learn More'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHealthAssessmentCard(BuildContext context, HealthAssessment health) {
    final theme = Theme.of(context);
    final isHealthy = health.isHealthy;
    final confidence = (health.isHealthyProbability * 100).toStringAsFixed(1);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isHealthy ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHealthy ? Icons.health_and_safety : Icons.warning_amber,
                    color: isHealthy ? AppTheme.successColor : AppTheme.warningColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHealthy ? 'Healthy Plant' : 'Health Issues Detected',
                        style: AppTheme.headlineMedium,
                      ),
                      Text(
                        'Confidence: $confidence%',
                        style: AppTheme.bodyMedium.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (!isHealthy && health.diseases.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Detected ${health.diseases.length} possible issue${health.diseases.length > 1 ? 's' : ''}',
                style: AppTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiseaseCard(BuildContext context, DiseaseSuggestion disease) {
    Theme.of(context);
    final confidence = (disease.probability * 100).toStringAsFixed(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bug_report,
            color: AppTheme.warningColor,
            size: 24,
          ),
        ),
        title: Text(
          disease.name,
          style: AppTheme.headlineSmall,
        ),
        subtitle: Text(
          'Probability: $confidence%',
          style: AppTheme.bodySmall,
        ),
        children: [
          if (disease.diseaseDetails.description != null) ...[
            _buildDetailSection(
              'Description',
              disease.diseaseDetails.description!,
              Icons.description,
            ),
          ],
          
          if (disease.diseaseDetails.cause != null) ...[
            const SizedBox(height: 16),
            _buildDetailSection(
              'Cause',
              disease.diseaseDetails.cause!,
              Icons.info_outline,
            ),
          ],
          
          if (disease.diseaseDetails.treatment != null) ...[
            const SizedBox(height: 16),
            _buildDetailSection(
              'Treatment',
              disease.diseaseDetails.treatment!,
              Icons.medical_services,
            ),
          ],
          
          if (disease.diseaseDetails.url != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl(disease.diseaseDetails.url!),
                icon: const Icon(Icons.open_in_new),
                label: const Text('More Information'),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Color _getConfidenceColor(double probability) {
    if (probability >= 0.8) return AppTheme.successColor;
    if (probability >= 0.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}