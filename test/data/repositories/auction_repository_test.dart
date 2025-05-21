import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kutanda/lib/data/models/auction_model.dart';
import 'package:kutanda/lib/data/repositories/auction_repository.dart';
import 'package:kutanda/lib/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For SupabaseClient, RealtimeChannel etc.

// Generate mocks by running `flutter pub run build_runner build`
@GenerateMocks([ApiService, SupabaseClient, RealtimeChannel, PostgrestFilterBuilder, StreamPostgrestFilterBuilder])
import 'auction_repository_test.mocks.dart'; // This file will be generated

void main() {
  late AuctionRepository auctionRepository;
  late MockApiService mockApiService;
  late MockSupabaseClient mockSupabaseClient;
  // Mocks for stream building
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockPostgrestFilterBuilderListMap;
  late MockStreamPostgrestFilterBuilder<List<Map<String, dynamic>>> mockStreamPostgrestFilterBuilderListMap;


  setUp(() {
    mockApiService = MockApiService();
    mockSupabaseClient = MockSupabaseClient();
    
    // Initialize the repository with mocks
    auctionRepository = AuctionRepository(
      apiService: mockApiService,
      supabase: mockSupabaseClient,
    );

    // Mocks for stream building - these might need to be more specific depending on usage
    mockPostgrestFilterBuilderListMap = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    mockStreamPostgrestFilterBuilderListMap = MockStreamPostgrestFilterBuilder<List<Map<String, dynamic>>>();

    // Common stubbing for Supabase stream methods
    // This setup is quite generic. Actual tests for stream methods will need more specific stubbing
    // for 'from', 'stream', 'eq', 'map' etc.
    when(mockSupabaseClient.from(any)).thenReturn(mockPostgrestFilterBuilderListMap);
    when(mockPostgrestFilterBuilderListMap.stream(primaryKey: anyNamed('primaryKey'))).thenReturn(mockStreamPostgrestFilterBuilderListMap);
    when(mockStreamPostgrestFilterBuilderListMap.eq(any, any)).thenReturn(mockStreamPostgrestFilterBuilderListMap);
    when(mockStreamPostgrestFilterBuilderListMap.map<List<Auction>>(any)).thenAnswer((_) => Stream.value([])); // Default empty stream
     when(mockStreamPostgrestFilterBuilderListMap.map<List<Map<String,dynamic>>>(any)).thenAnswer((_) => Stream.value([]));


  });

  // Helper for creating a dummy Auction model
  final testAuction = Auction(
    id: 'test_id',
    productName: 'Test Product',
    productDescription: 'Description',
    startingPrice: 100.0,
    currentPrice: 100.0,
    highestBid: 100.0,
    sellerId: 'seller_id',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(Duration(days: 1)),
    isActive: true,
    isSold: false,
    imageUrl: 'http://example.com/image.png',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testAuctionMap = testAuction.toMap();
  final List<Map<String, dynamic>> testAuctionListMap = [testAuctionMap];

  group('AuctionRepository - CRUD using ApiService', () {
    group('createAuction', () {
      test('returns true on successful creation', () async {
        when(mockApiService.post('auctions', testAuctionMap))
            .thenAnswer((_) async => {'data': testAuctionMap}); // Simulate successful response
        
        final result = await auctionRepository.createAuction(testAuction);
        
        expect(result, isTrue);
        verify(mockApiService.post('auctions', testAuctionMap)).called(1);
      });

      test('returns false when ApiService returns null', () async {
        when(mockApiService.post('auctions', testAuctionMap))
            .thenAnswer((_) async => null);
        
        final result = await auctionRepository.createAuction(testAuction);
        
        expect(result, isFalse);
      });

      test('returns false on ApiService exception', () async {
        when(mockApiService.post('auctions', testAuctionMap))
            .thenThrow(Exception('API Error'));
        
        final result = await auctionRepository.createAuction(testAuction);
        
        expect(result, isFalse);
      });
    });

    group('getAllAuctions', () {
      test('returns list of auctions on success', () async {
        when(mockApiService.get('auctions?order=created_at.desc'))
            .thenAnswer((_) async => {'data': testAuctionListMap});
        
        final result = await auctionRepository.getAllAuctions();
        
        expect(result, isA<List<Auction>>());
        expect(result.length, 1);
        expect(result.first.id, testAuction.id);
      });

      test('returns empty list when ApiService returns null', () async {
        when(mockApiService.get('auctions?order=created_at.desc'))
            .thenAnswer((_) async => null);
        
        final result = await auctionRepository.getAllAuctions();
        
        expect(result, isEmpty);
      });

       test('returns empty list when ApiService response data is not a list', () async {
        when(mockApiService.get('auctions?order=created_at.desc'))
            .thenAnswer((_) async => {'data': 'not_a_list'});
        
        final result = await auctionRepository.getAllAuctions();
        
        expect(result, isEmpty);
      });

      test('returns empty list on ApiService exception', () async {
        when(mockApiService.get('auctions?order=created_at.desc'))
            .thenThrow(Exception('API Error'));
        
        final result = await auctionRepository.getAllAuctions();
        
        expect(result, isEmpty);
      });
    });

    group('getActiveAuctions', () {
      test('returns list of active auctions on success', () async {
        when(mockApiService.get('auctions?is_active=eq.true&order=created_at.desc'))
            .thenAnswer((_) async => {'data': testAuctionListMap});
        
        final result = await auctionRepository.getActiveAuctions();
        
        expect(result.length, 1);
        expect(result.first.id, testAuction.id);
      });
       test('returns empty list when ApiService returns null', () async {
        when(mockApiService.get('auctions?is_active=eq.true&order=created_at.desc'))
            .thenAnswer((_) async => null);
        final result = await auctionRepository.getActiveAuctions();
        expect(result, isEmpty);
      });
    });

    group('getSellerAuctions', () {
      const sellerId = 'seller_id';
      test('returns list of seller auctions on success', () async {
        when(mockApiService.get('auctions?seller_id=eq.$sellerId&order=created_at.desc'))
            .thenAnswer((_) async => {'data': testAuctionListMap});
        
        final result = await auctionRepository.getSellerAuctions(sellerId);
        
        expect(result.length, 1);
        expect(result.first.id, testAuction.id);
      });
       test('returns empty list when ApiService returns null', () async {
        when(mockApiService.get('auctions?seller_id=eq.$sellerId&order=created_at.desc'))
            .thenAnswer((_) async => null);
        final result = await auctionRepository.getSellerAuctions(sellerId);
        expect(result, isEmpty);
      });
    });

    group('getAuctionById', () {
      const auctionId = 'test_id';
      test('returns auction on success', () async {
        when(mockApiService.get('auctions?id=eq.$auctionId&limit=1'))
            .thenAnswer((_) async => {'data': testAuctionListMap}); // API returns a list
        
        final result = await auctionRepository.getAuctionById(auctionId);
        
        expect(result, isNotNull);
        expect(result!.id, auctionId);
      });

      test('returns null if auction not found (empty list from API)', () async {
        when(mockApiService.get('auctions?id=eq.$auctionId&limit=1'))
            .thenAnswer((_) async => {'data': []});
        
        final result = await auctionRepository.getAuctionById(auctionId);
        
        expect(result, isNull);
      });

      test('returns null when ApiService returns null', () async {
        when(mockApiService.get('auctions?id=eq.$auctionId&limit=1'))
            .thenAnswer((_) async => null);
        
        final result = await auctionRepository.getAuctionById(auctionId);
        
        expect(result, isNull);
      });
    });

    group('updateAuction', () {
      test('returns true on successful update', () async {
        when(mockApiService.put('auctions?id=eq.${testAuction.id}', testAuctionMap))
            .thenAnswer((_) async => {'data': testAuctionMap});
        
        final result = await auctionRepository.updateAuction(testAuction);
        
        expect(result, isTrue);
      });
      test('returns false when ApiService returns null', () async {
        when(mockApiService.put('auctions?id=eq.${testAuction.id}', testAuctionMap))
            .thenAnswer((_) async => null);
        final result = await auctionRepository.updateAuction(testAuction);
        expect(result, isFalse);
      });
    });

    group('deleteAuction', () {
      const auctionId = 'test_id';
      test('returns true on successful deletion', () async {
        when(mockApiService.delete('auctions?id=eq.$auctionId'))
            .thenAnswer((_) async => {'status': 'success'}); // Success indicator
        
        final result = await auctionRepository.deleteAuction(auctionId);
        
        expect(result, isTrue);
      });
       test('returns false when ApiService returns null', () async {
        when(mockApiService.delete('auctions?id=eq.$auctionId'))
            .thenAnswer((_) async => null);
        final result = await auctionRepository.deleteAuction(auctionId);
        expect(result, isFalse);
      });
    });

    group('placeBid', () {
      const auctionId = 'test_id';
      const bidAmount = 150.0;
      const bidderId = 'bidder_user_id';
      final bidData = {
        'auction_id': auctionId,
        'bid_amount': bidAmount,
        'bidder_id': bidderId,
      };

      test('returns true on successful bid placement', () async {
        when(mockApiService.post('place-bid', bidData))
            .thenAnswer((_) async => {'data': {'success': true}});
        
        final result = await auctionRepository.placeBid(auctionId, bidAmount, bidderId);
        
        expect(result, isTrue);
      });

      test('returns false if bid placement fails (success: false)', () async {
         when(mockApiService.post('place-bid', bidData))
            .thenAnswer((_) async => {'data': {'success': false}});
        final result = await auctionRepository.placeBid(auctionId, bidAmount, bidderId);
        expect(result, isFalse);
      });
      
      test('returns false if bid placement response is not as expected', () async {
         when(mockApiService.post('place-bid', bidData))
            .thenAnswer((_) async => {'data': {'unexpected_key': true}}); // Malformed success response
        final result = await auctionRepository.placeBid(auctionId, bidAmount, bidderId);
        expect(result, isFalse);
      });

      test('returns false when ApiService returns null for placeBid', () async {
        when(mockApiService.post('place-bid', bidData))
            .thenAnswer((_) async => null);
        final result = await auctionRepository.placeBid(auctionId, bidAmount, bidderId);
        expect(result, isFalse);
      });
    });

    group('getAuctionBids', () {
      const auctionId = 'test_id';
      final bidMap = {'bid_id': 'b1', 'amount': 120.0, 'bidder_id': 'user1'};
      final List<Map<String, dynamic>> bidsListMap = [bidMap];

      test('returns list of bids on success', () async {
        const queryString = 'bids?auction_id=eq.$auctionId&select=*,bidder:profiles!bidder_id(display_name,email)&order=created_at.desc';
        when(mockApiService.get(queryString))
            .thenAnswer((_) async => {'data': bidsListMap});
        
        final result = await auctionRepository.getAuctionBids(auctionId);
        
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result.first['bid_id'], 'b1');
      });
       test('returns empty list when ApiService returns null', () async {
        const queryString = 'bids?auction_id=eq.$auctionId&select=*,bidder:profiles!bidder_id(display_name,email)&order=created_at.desc';
        when(mockApiService.get(queryString)).thenAnswer((_) async => null);
        final result = await auctionRepository.getAuctionBids(auctionId);
        expect(result, isEmpty);
      });
    });
  });

  group('AuctionRepository - Stream methods using SupabaseClient', () {
    // Note: Testing streams is complex. These tests verify setup.
    // Actual stream content testing would require more intricate mock stream controllers.

    setUp(() {
      // Specific setup for stream tests if different from general ApiService tests
      // Ensure the mockSupabaseClient.from().stream()... chain is correctly set up.
      // This might involve creating specific mock instances for each call in the chain if they return different types.
      
      // Example of more specific setup for a stream that returns List<Auction>
      final mockStreamFilterBuilderForAuctions = MockStreamPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(mockSupabaseClient.from('auctions')).thenReturn(mockPostgrestFilterBuilderListMap);
      when(mockPostgrestFilterBuilderListMap.stream(primaryKey: ['id'])).thenReturn(mockStreamFilterBuilderForAuctions);
      when(mockStreamFilterBuilderForAuctions.eq(any, any)).thenReturn(mockStreamFilterBuilderForAuctions); // For seller auctions
      when(mockStreamFilterBuilderForAuctions.map<List<Auction>>(any)).thenAnswer((invocation) {
        // Get the mapper function passed to `map`
        final mapper = invocation.positionalArguments.first as List<Auction> Function(List<Map<String, dynamic>>);
        // Return a stream that applies this mapper to some dummy data
        return Stream.value([testAuctionMap]).map(mapper);
      });

      // Example for a stream that returns List<Map<String, dynamic>> (for bids)
      final mockStreamFilterBuilderForBids = MockStreamPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(mockSupabaseClient.from('bids')).thenReturn(mockPostgrestFilterBuilderListMap);
      when(mockPostgrestFilterBuilderListMap.stream(primaryKey: ['id'])).thenReturn(mockStreamFilterBuilderForBids);
      when(mockStreamFilterBuilderForBids.eq('auction_id', any)).thenReturn(mockStreamFilterBuilderForBids);
      when(mockStreamFilterBuilderForBids.map<List<Map<String, dynamic>>>(any)).thenAnswer((invocation) {
         final mapper = invocation.positionalArguments.first as List<Map<String,dynamic>> Function(List<Map<String, dynamic>>);
        return Stream.value([{'bid_id': 'b1'}]).map(mapper);
      });
    });
    
    test('listenToAuctions sets up stream correctly', () {
      final stream = auctionRepository.listenToAuctions();
      expect(stream, isA<Stream<List<Auction>>>());
      // Further test by listening to the stream and expecting mapped data
      stream.listen(
        expectAsync1((auctions) {
          expect(auctions, isA<List<Auction>>());
          expect(auctions.length, 1);
          expect(auctions.first.id, testAuction.id);
        }),
      );
      verify(mockSupabaseClient.from('auctions')).called(1);
      verify(mockPostgrestFilterBuilderListMap.stream(primaryKey: ['id'])).called(1);
    });

    test('listenToSellerAuctions sets up stream with filter correctly', () {
      const sellerId = 'seller_id_test';
      final stream = auctionRepository.listenToSellerAuctions(sellerId);
      expect(stream, isA<Stream<List<Auction>>>());

      stream.listen(
        expectAsync1((auctions) {
          expect(auctions, isA<List<Auction>>());
          // Add more specific data checks if mapper is fully mocked
        }),
      );

      verify(mockSupabaseClient.from('auctions')).called(1);
      verify(mockPostgrestFilterBuilderListMap.stream(primaryKey: ['id'])).called(1);
      // verify(mockStreamPostgrestFilterBuilderListMap.eq('seller_id', sellerId)).called(1); // This was the generic one
      final StreamPostgrestFilterBuilder<List<Map<String, dynamic>>> captured = verify(mockSupabaseClient.from('auctions').stream(primaryKey: ['id']).eq('seller_id', captureAny)).captured.single;
      expect(captured, isNotNull); // Check if eq was called
    });

    test('listenToAuctionBids sets up stream with filter correctly', () {
      const auctionId = 'auction_id_test';
      final stream = auctionRepository.listenToAuctionBids(auctionId);
      expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      
      stream.listen(
        expectAsync1((bids) {
          expect(bids, isA<List<Map<String, dynamic>>>());
          // Add more specific data checks
        }),
      );

      verify(mockSupabaseClient.from('bids')).called(1);
      verify(mockPostgrestFilterBuilderListMap.stream(primaryKey: ['id'])).called(1);
      // verify(mockStreamPostgrestFilterBuilderListMap.eq('auction_id', auctionId)).called(1);
      final StreamPostgrestFilterBuilder<List<Map<String, dynamic>>> captured = verify(mockSupabaseClient.from('bids').stream(primaryKey: ['id']).eq('auction_id', captureAny)).captured.single;
       expect(captured, isNotNull);
    });
  });
}
