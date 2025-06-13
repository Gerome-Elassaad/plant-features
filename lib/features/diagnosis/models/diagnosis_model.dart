class DiagnosisResponse {
  final bool success;
  final DiagnosisData data;
  
  DiagnosisResponse({
    required this.success,
    required this.data,
  });
  
  factory DiagnosisResponse.fromJson(Map<String, dynamic> json) {
    return DiagnosisResponse(
      success: json['success'] ?? false,
      data: DiagnosisData.fromJson(json['data'] ?? {}),
    );
  }
}

class DiagnosisData {
  final bool isPlant;
  final double isPlantProbability;
  final List<PlantSuggestion> suggestions;
  final HealthAssessment? healthAssessment;
  final List<DiseaseSuggestion> diseaseSuggestions;
  final DiagnosisMetadata metadata;
  
  DiagnosisData({
    required this.isPlant,
    required this.isPlantProbability,
    required this.suggestions,
    this.healthAssessment,
    required this.diseaseSuggestions,
    required this.metadata,
  });
  
  factory DiagnosisData.fromJson(Map<String, dynamic> json) {
    return DiagnosisData(
      isPlant: json['is_plant'] ?? false,
      isPlantProbability: (json['is_plant_probability'] ?? 0.0).toDouble(),
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((s) => PlantSuggestion.fromJson(s))
          .toList() ?? [],
      healthAssessment: json['health_assessment'] != null
          ? HealthAssessment.fromJson(json['health_assessment'])
          : null,
      diseaseSuggestions: (json['disease_suggestions'] as List<dynamic>?)
          ?.map((d) => DiseaseSuggestion.fromJson(d))
          .toList() ?? [],
      metadata: DiagnosisMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class PlantSuggestion {
  final String id;
  final String plantName;
  final PlantDetails plantDetails;
  final double probability;
  final bool confirmed;
  final List<SimilarImage> similarImages;
  
  PlantSuggestion({
    required this.id,
    required this.plantName,
    required this.plantDetails,
    required this.probability,
    required this.confirmed,
    required this.similarImages,
  });
  
  factory PlantSuggestion.fromJson(Map<String, dynamic> json) {
    return PlantSuggestion(
      id: json['id'] ?? '',
      plantName: json['plant_name'] ?? '',
      plantDetails: PlantDetails.fromJson(json['plant_details'] ?? {}),
      probability: (json['probability'] ?? 0.0).toDouble(),
      confirmed: json['confirmed'] ?? false,
      similarImages: (json['similar_images'] as List<dynamic>?)
          ?.map((img) => SimilarImage.fromJson(img))
          .toList() ?? [],
    );
  }
}

class PlantDetails {
  final String scientificName;
  final List<String> commonNames;
  final String? url;
  final String? description;
  final List<String> synonyms;
  final String? image;
  
  PlantDetails({
    required this.scientificName,
    required this.commonNames,
    this.url,
    this.description,
    required this.synonyms,
    this.image,
  });
  
  factory PlantDetails.fromJson(Map<String, dynamic> json) {
    return PlantDetails(
      scientificName: json['scientific_name'] ?? '',
      commonNames: List<String>.from(json['common_names'] ?? []),
      url: json['url'],
      description: json['description'],
      synonyms: List<String>.from(json['synonyms'] ?? []),
      image: json['image'],
    );
  }
}

class HealthAssessment {
  final bool isHealthy;
  final double isHealthyProbability;
  final List<DiseaseSuggestion> diseases;
  
  HealthAssessment({
    required this.isHealthy,
    required this.isHealthyProbability,
    required this.diseases,
  });
  
  factory HealthAssessment.fromJson(Map<String, dynamic> json) {
    return HealthAssessment(
      isHealthy: json['is_healthy'] ?? true,
      isHealthyProbability: (json['is_healthy_probability'] ?? 1.0).toDouble(),
      diseases: (json['diseases'] as List<dynamic>?)
          ?.map((d) => DiseaseSuggestion.fromJson(d))
          .toList() ?? [],
    );
  }
}

class DiseaseSuggestion {
  final String id;
  final String name;
  final double probability;
  final DiseaseDetails diseaseDetails;
  final List<SimilarImage> similarImages;
  
  DiseaseSuggestion({
    required this.id,
    required this.name,
    required this.probability,
    required this.diseaseDetails,
    required this.similarImages,
  });
  
  factory DiseaseSuggestion.fromJson(Map<String, dynamic> json) {
    return DiseaseSuggestion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      probability: (json['probability'] ?? 0.0).toDouble(),
      diseaseDetails: DiseaseDetails.fromJson(json['disease_details'] ?? {}),
      similarImages: (json['similar_images'] as List<dynamic>?)
          ?.map((img) => SimilarImage.fromJson(img))
          .toList() ?? [],
    );
  }
}

class DiseaseDetails {
  final String? description;
  final String? treatment;
  final String? cause;
  final String? url;
  
  DiseaseDetails({
    this.description,
    this.treatment,
    this.cause,
    this.url,
  });
  
  factory DiseaseDetails.fromJson(Map<String, dynamic> json) {
    return DiseaseDetails(
      description: json['description'],
      treatment: json['treatment'],
      cause: json['cause'],
      url: json['url'],
    );
  }
}

class SimilarImage {
  final String id;
  final String url;
  final double similarity;
  
  SimilarImage({
    required this.id,
    required this.url,
    required this.similarity,
  });
  
  factory SimilarImage.fromJson(Map<String, dynamic> json) {
    return SimilarImage(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      similarity: (json['similarity'] ?? 0.0).toDouble(),
    );
  }
}

class DiagnosisMetadata {
  final String date;
  final String? version;
  final String? customId;
  final LocationData? location;
  
  DiagnosisMetadata({
    required this.date,
    this.version,
    this.customId,
    this.location,
  });
  
  factory DiagnosisMetadata.fromJson(Map<String, dynamic> json) {
    return DiagnosisMetadata(
      date: json['date'] ?? DateTime.now().toIso8601String(),
      version: json['version'],
      customId: json['custom_id'],
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  
  LocationData({
    required this.latitude,
    required this.longitude,
  });
  
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}