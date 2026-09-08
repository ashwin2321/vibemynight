/// Request payloads for admin write operations, matching the backend's
/// Create*Request DTOs field-for-field. Kept in one file since each is small.
library;

class CreateEventRequest {
  final String name;
  final String slug;
  final String? mainImage;
  final String? banner;
  final String? thumbnail;
  final String? description;
  final String startDate; // yyyy-MM-dd
  final String endDate;
  final String? venue;
  final String? address;
  final String? city;
  final String? location;
  final String? googleMapsUrl;
  final String? organizer;
  final String? contactNumber;
  final String? email;
  final bool featured;

  const CreateEventRequest({
    required this.name,
    required this.slug,
    this.mainImage,
    this.banner,
    this.thumbnail,
    this.description,
    required this.startDate,
    required this.endDate,
    this.venue,
    this.address,
    this.city,
    this.location,
    this.googleMapsUrl,
    this.organizer,
    this.contactNumber,
    this.email,
    this.featured = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'mainImage': mainImage,
        'banner': banner,
        'thumbnail': thumbnail,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'venue': venue,
        'address': address,
        'city': city,
        'location': location,
        'googleMapsUrl': googleMapsUrl,
        'organizer': organizer,
        'contactNumber': contactNumber,
        'email': email,
        'featured': featured,
      };
}

class CreateEventDayRequest {
  final int dayNumber;
  final String date;
  final String? dayName;
  final String? programName;
  final String? startTime; // HH:mm
  final String? endTime;
  final String? venue;
  final String? address;
  final String? location;
  final String? googleMapsUrl;
  final String? description;

  const CreateEventDayRequest({
    required this.dayNumber,
    required this.date,
    this.dayName,
    this.programName,
    this.startTime,
    this.endTime,
    this.venue,
    this.address,
    this.location,
    this.googleMapsUrl,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'date': date,
        'dayName': dayName,
        'programName': programName,
        'startTime': startTime,
        'endTime': endTime,
        'venue': venue,
        'address': address,
        'location': location,
        'googleMapsUrl': googleMapsUrl,
        'description': description,
      };
}

class CreateArtistRequest {
  final String name;
  final String slug;
  final String? photoUrl;
  final String type;
  final String? shortBio;
  final String? fullBio;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? youtubeUrl;
  final bool featured;

  const CreateArtistRequest({
    required this.name,
    required this.slug,
    this.photoUrl,
    required this.type,
    this.shortBio,
    this.fullBio,
    this.instagramUrl,
    this.facebookUrl,
    this.youtubeUrl,
    this.featured = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'photoUrl': photoUrl,
        'type': type,
        'shortBio': shortBio,
        'fullBio': fullBio,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
        'youtubeUrl': youtubeUrl,
        'featured': featured,
      };
}

class CreateFacilityRequest {
  final String name;
  final String? icon;
  final String? description;

  const CreateFacilityRequest({required this.name, this.icon, this.description});

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon, 'description': description};
}

class CreateTicketCategoryRequest {
  final String name;
  final String type;
  final double price;
  final int availableQuantity;
  final int maxPerCustomer;
  final String? description;
  final List<String> benefits;

  const CreateTicketCategoryRequest({
    required this.name,
    required this.type,
    required this.price,
    required this.availableQuantity,
    this.maxPerCustomer = 10,
    this.description,
    this.benefits = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'price': price,
        'availableQuantity': availableQuantity,
        'maxPerCustomer': maxPerCustomer,
        'description': description,
        'benefits': benefits,
      };
}

class AssignArtistToDayRequest {
  final int artistId;
  final bool isPrimary;
  final int? performanceOrder;
  final String? performanceStartTime;
  final String? performanceEndTime;

  const AssignArtistToDayRequest({
    required this.artistId,
    this.isPrimary = false,
    this.performanceOrder,
    this.performanceStartTime,
    this.performanceEndTime,
  });

  Map<String, dynamic> toJson() => {
        'artistId': artistId,
        'isPrimary': isPrimary,
        'performanceOrder': performanceOrder,
        'performanceStartTime': performanceStartTime,
        'performanceEndTime': performanceEndTime,
      };
}
