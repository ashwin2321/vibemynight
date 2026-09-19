import 'package:flutter_test/flutter_test.dart';
import 'package:vibemynight/core/utils/csv_exporter.dart';
import 'package:vibemynight/models/admin_requests.dart';
import 'package:vibemynight/models/admin_user.dart';
import 'package:vibemynight/models/event_day_detail.dart';
import 'package:vibemynight/models/event_detail.dart';
import 'package:vibemynight/models/event_import_models.dart';
import 'package:vibemynight/models/event_summary.dart';
import 'package:vibemynight/models/inquiry.dart';
import 'package:vibemynight/models/inquiry_admin_summary.dart';
import 'package:vibemynight/models/settings.dart';
import 'package:vibemynight/models/upi_payment.dart';

void main() {
  group('Models JSON Serialization / Deserialization Tests', () {
    test('EventSummary.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Navratri Nights 2026',
        'slug': 'navratri-nights-2026',
        'mainImage': 'https://example.com/main.jpg',
        'thumbnail': 'https://example.com/thumb.jpg',
        'city': 'Ahmedabad',
        'location': 'Grand Arena',
        'startDate': '2026-10-15',
        'endDate': '2026-10-19',
        'dayCount': 5,
        'startingPrice': 499.0,
        'featuredArtistName': 'Falguni Pathak',
        'featured': true,
        'status': 'PUBLISHED',
      };

      final event = EventSummary.fromJson(json);

      expect(event.id, 1);
      expect(event.name, 'Navratri Nights 2026');
      expect(event.slug, 'navratri-nights-2026');
      expect(event.city, 'Ahmedabad');
      expect(event.dayCount, 5);
      expect(event.startingPrice, 499.0);
      expect(event.featuredArtistName, 'Falguni Pathak');
      expect(event.featured, isTrue);
      expect(event.status, 'PUBLISHED');
    });

    test('EventDetail.fromJson parses correctly with facilities and days', () {
      final json = {
        'id': 1,
        'name': 'Navratri Nights 2026',
        'slug': 'navratri-nights-2026',
        'description': 'Experience the grandest Navratri festival',
        'startDate': '2026-10-15',
        'endDate': '2026-10-19',
        'venue': 'Grand Arena',
        'city': 'Ahmedabad',
        'featured': true,
        'status': 'PUBLISHED',
        'galleryImageUrls': ['https://example.com/g1.jpg', 'https://example.com/g2.jpg'],
        'highlights': ['Live Singer', 'Laser Show'],
        'rules': ['Traditional attire preferred', 'No outside food'],
        'facilities': [
          {'id': 10, 'name': 'Parking', 'description': 'Free parking', 'status': 'ACTIVE'}
        ],
        'days': [
          {
            'id': 101,
            'dayNumber': 1,
            'date': '2026-10-15',
            'programName': 'Opening Night',
            'startingPrice': 499.0,
          }
        ],
      };

      final eventDetail = EventDetail.fromJson(json);

      expect(eventDetail.id, 1);
      expect(eventDetail.highlights.length, 2);
      expect(eventDetail.rules.length, 2);
      expect(eventDetail.facilities.length, 1);
      expect(eventDetail.facilities.first.name, 'Parking');
      expect(eventDetail.days.length, 1);
      expect(eventDetail.days.first.dayNumber, 1);
    });

    test('EventDayDetail.fromJson parses passes and artists correctly', () {
      final json = {
        'id': 101,
        'eventId': 1,
        'dayNumber': 1,
        'date': '2026-10-15',
        'programName': 'Opening Garba Night',
        'startTime': '08:00 PM',
        'endTime': '01:00 AM',
        'venue': 'Grand Arena',
        'location': 'Near GMDC',
        'status': 'ACTIVE',
        'passes': [
          {
            'id': 201,
            'eventDayId': 101,
            'name': 'VIP Pass',
            'type': 'VIP',
            'price': 999.0,
            'availableQuantity': 25,
            'maxPerCustomer': 5,
            'benefits': ['VIP entry', 'Refreshments included'],
            'status': 'AVAILABLE',
            'soldOut': false,
          }
        ],
        'artists': [
          {
            'artistId': 50,
            'name': 'Falguni Pathak',
            'type': 'Garba Queen',
            'isPrimary': true,
            'performanceOrder': 1,
          }
        ],
        'facilities': [],
      };

      final dayDetail = EventDayDetail.fromJson(json);

      expect(dayDetail.id, 101);
      expect(dayDetail.programName, 'Opening Garba Night');
      expect(dayDetail.passes.length, 1);
      expect(dayDetail.passes.first.name, 'VIP Pass');
      expect(dayDetail.passes.first.price, 999.0);
      expect(dayDetail.artists.length, 1);
      expect(dayDetail.primaryArtist?.name, 'Falguni Pathak');
    });

    test('CreateInquiryRequest serializes to JSON correctly without client-side price', () {
      const req = CreateInquiryRequest(
        customerName: 'Rahul Sharma',
        customerMobile: '9876543210',
        customerEmail: 'rahul@example.com',
        eventDayId: 101,
        ticketCategoryId: 201,
        quantity: 3,
        message: 'Looking forward to the event!',
      );

      final json = req.toJson();

      expect(json['customerName'], 'Rahul Sharma');
      expect(json['customerMobile'], '9876543210');
      expect(json['customerEmail'], 'rahul@example.com');
      expect(json['eventDayId'], 101);
      expect(json['ticketCategoryId'], 201);
      expect(json['quantity'], 3);
      expect(json['message'], 'Looking forward to the event!');
      expect(json.containsKey('price'), isFalse);
      expect(json.containsKey('estimatedTotal'), isFalse);
    });

    test('InquiryResponse parses from backend JSON correctly', () {
      final json = {
        'id': 88,
        'inquiryNumber': 'VMN-123456',
        'status': 'NEW',
        'customerName': 'Rahul Sharma',
        'customerMobile': '9876543210',
        'eventId': 1,
        'eventName': 'Navratri Nights 2026',
        'eventDayId': 101,
        'dayNumber': 1,
        'date': '2026-10-15',
        'ticketCategoryId': 201,
        'ticketCategoryName': 'VIP Pass',
        'price': 999.0,
        'quantity': 2,
        'estimatedTotal': 1998.0,
        'whatsappNumber': '917041615131',
        'whatsappUrl': 'https://wa.me/917041615131?text=Hi',
      };

      final response = InquiryResponse.fromJson(json);

      expect(response.id, 88);
      expect(response.inquiryNumber, 'VMN-123456');
      expect(response.status, 'NEW');
      expect(response.estimatedTotal, 1998.0);
      expect(response.whatsappUrl, 'https://wa.me/917041615131?text=Hi');
    });

    test('AppSettings.fromJson parses correctly', () {
      final json = {
        'websiteName': 'VibeMyNight',
        'whatsappNumber': '917041615131',
        'phone': '+91 70416 15131',
        'email': 'hello@vibemynight.com',
        'currency': 'INR',
        'footerText': '© 2026 VibeMyNight. All rights reserved.',
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.websiteName, 'VibeMyNight');
      expect(settings.whatsappNumber, '917041615131');
      expect(settings.currency, 'INR');
    });

    test('LoginResult.fromJson and AssignArtistToDayRequest work as expected', () {
      final userJson = {
        'accessToken': 'jwt.token.here',
        'tokenType': 'Bearer',
        'userId': 1,
        'name': 'admin',
        'email': 'admin@vibemynight.com',
        'role': 'ROLE_ADMIN',
      };
      final user = LoginResult.fromJson(userJson);
      expect(user.name, 'admin');
      expect(user.email, 'admin@vibemynight.com');
      expect(user.accessToken, 'jwt.token.here');

      const assignReq = AssignArtistToDayRequest(
        artistId: 50,
        isPrimary: true,
        performanceOrder: 1,
        performanceStartTime: '08:00 PM',
        performanceEndTime: '11:00 PM',
      );
      final assignJson = assignReq.toJson();
      expect(assignJson['artistId'], 50);
      expect(assignJson['isPrimary'], isTrue);
      expect(assignJson['performanceOrder'], 1);
      expect(assignJson['performanceStartTime'], '08:00 PM');
    });

    test('InquiryAdminSummary.fromJson parses table row correctly', () {
      final summaryJson = {
        'id': 101,
        'inquiryNumber': 'VMN-2026-0001',
        'customerName': 'Aarav Patel',
        'customerMobile': '919876543210',
        'eventName': 'Sunburn Arena',
        'dayNumber': 1,
        'date': '2026-11-20',
        'artistName': 'DJ Snake',
        'ticketCategoryName': 'VIP Pass',
        'price': 2499.0,
        'quantity': 2,
        'estimatedTotal': 4998.0,
        'status': 'CONFIRMED',
        'createdAt': '2026-09-08T12:00:00Z',
      };
      final summary = InquiryAdminSummary.fromJson(summaryJson);
      expect(summary.id, 101);
      expect(summary.inquiryNumber, 'VMN-2026-0001');
      expect(summary.customerName, 'Aarav Patel');
      expect(summary.customerMobile, '919876543210');
      expect(summary.eventName, 'Sunburn Arena');
      expect(summary.ticketCategoryName, 'VIP Pass');
      expect(summary.price, 2499.0);
      expect(summary.quantity, 2);
      expect(summary.estimatedTotal, 4998.0);
      expect(summary.status, 'CONFIRMED');
    });

    test('CsvExporter handles empty lists safely', () async {
      final result = await CsvExporter.exportInquiries([]);
      expect(result, isFalse);
    });

    test('EventImportPreview.fromJson and toJson work correctly', () {
      final previewJson = {
        'event': {
          'name': 'Navratri Grand 2026',
          'slug': 'navratri-grand-2026',
          'startDate': '2026-10-15',
          'endDate': '2026-10-17',
          'city': 'Ahmedabad',
          'featured': true,
          'status': 'PUBLISHED',
        },
        'days': [
          {
            'dayNumber': 1,
            'date': '2026-10-15',
            'programName': 'Opening Garba',
            'passes': [
              {
                'dayNumber': '1',
                'name': 'VIP Pass',
                'type': 'VIP',
                'price': 1299.0,
                'availableQuantity': 150,
                'benefits': ['VIP Entry', 'Drinks'],
              }
            ],
            'artists': [
              {
                'dayNumber': 1,
                'artistName': 'Falguni Pathak',
                'artistType': 'SINGER',
                'isPrimary': true,
              }
            ],
            'facilities': [
              {
                'name': 'Free Parking',
                'scope': 'EVENT',
              }
            ],
          }
        ],
        'eventFacilities': [
          {
            'name': 'Valet Parking',
            'scope': 'EVENT',
          }
        ],
        'highlights': ['Air conditioned arena'],
        'rules': ['Traditional attire required'],
        'validationMessages': [
          {
            'level': 'WARNING',
            'sheet': 'ARTISTS',
            'message': 'Artist is new',
          }
        ],
        'hasBlockingErrors': false,
        'totalDays': 1,
        'totalPasses': 1,
        'totalArtists': 1,
      };

      final preview = EventImportPreview.fromJson(previewJson);
      expect(preview.event?.name, 'Navratri Grand 2026');
      expect(preview.days.length, 1);
      expect(preview.days.first.passes.first.name, 'VIP Pass');
      expect(preview.days.first.passes.first.price, 1299.0);
      expect(preview.days.first.artists.first.artistName, 'Falguni Pathak');
      expect(preview.days.first.artists.first.isPrimary, isTrue);
      expect(preview.eventFacilities.first.name, 'Valet Parking');
      expect(preview.highlights.first, 'Air conditioned arena');
      expect(preview.hasBlockingErrors, isFalse);
      expect(preview.validationMessages.first.isWarning, isTrue);

      final encodedJson = preview.toJson();
      expect(encodedJson['totalDays'], 1);
      expect((encodedJson['event'] as Map)['name'], 'Navratri Grand 2026');
    });

    test('ScrapedImageCandidate.effectiveUrl prioritizes localUrl over external url', () {
      const candidateWithBoth = ScrapedImageCandidate(
        url: 'https://b.zmtcdn.com/data/district_events/poster.jpg',
        localUrl: '/uploads/events/artwork-123.jpg',
        suggestedRole: 'POSTER_3_4',
      );
      expect(candidateWithBoth.effectiveUrl, '/uploads/events/artwork-123.jpg');

      const candidateOnlyExternal = ScrapedImageCandidate(
        url: 'https://images.unsplash.com/poster.jpg',
        localUrl: null,
        suggestedRole: 'POSTER_3_4',
      );
      expect(candidateOnlyExternal.effectiveUrl, 'https://images.unsplash.com/poster.jpg');

      const candidateEmptyLocal = ScrapedImageCandidate(
        url: 'https://images.unsplash.com/poster.jpg',
        localUrl: '   ',
        suggestedRole: 'POSTER_3_4',
      );
      expect(candidateEmptyLocal.effectiveUrl, 'https://images.unsplash.com/poster.jpg');
    });

    test('AppSettings.fromJson parses upiEnabled, upiVpa, upiMerchantName safely', () {
      final jsonWithUpi = {
        'id': 1,
        'brandName': 'VibeMyNight',
        'whatsappNumber': '917041615131',
        'upiEnabled': true,
        'upiVpa': 'vibemynight@icici',
        'upiMerchantName': 'VibeMyNight Live',
      };
      final settings = AppSettings.fromJson(jsonWithUpi);
      expect(settings.upiEnabled, isTrue);
      expect(settings.upiVpa, 'vibemynight@icici');
      expect(settings.upiMerchantName, 'VibeMyNight Live');

      final jsonWithoutUpi = {
        'id': 1,
        'brandName': 'VibeMyNight',
        'whatsappNumber': '917041615131',
      };
      final fallbackSettings = AppSettings.fromJson(jsonWithoutUpi);
      expect(fallbackSettings.upiEnabled, isFalse);
      expect(fallbackSettings.upiVpa, isNull);
    });

    test('UpiPaymentResponse.fromJson parses server payment response correctly', () {
      final json = {
        'transactionReference': 'VMN-UPI-1789809400-ABCD',
        'upiUrl': 'upi://pay?pa=vibemynight@icici&pn=VibeMyNight&am=1497.00&tr=VMN-UPI-1789809400-ABCD&tn=Booking+Payment&cu=INR',
        'totalAmount': 1497.0,
        'upiVpa': 'vibemynight@icici',
        'merchantName': 'VibeMyNight',
        'status': 'INITIATED',
        'itemizedBreakdown': ['Regular Pass x 3 (Rs 1497)'],
        'note': 'Passes for Navratri',
      };
      final res = UpiPaymentResponse.fromJson(json);
      expect(res.transactionReference, 'VMN-UPI-1789809400-ABCD');
      expect(res.totalAmount, 1497.0);
      expect(res.upiVpa, 'vibemynight@icici');
      expect(res.merchantName, 'VibeMyNight');
      expect(res.status, 'INITIATED');
      expect(res.itemizedBreakdown.length, 1);
      expect(res.upiUrl, contains('upi://pay'));
    });
  });
}
