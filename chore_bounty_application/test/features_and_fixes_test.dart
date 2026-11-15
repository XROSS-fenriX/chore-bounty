import 'package:chore_bounty_application/core/api_client.dart';
import 'package:chore_bounty_application/core/token_storage.dart';
import 'package:chore_bounty_application/models/app_notification.dart';
import 'package:chore_bounty_application/models/app_user.dart';
import 'package:chore_bounty_application/models/bounty.dart';
import 'package:chore_bounty_application/models/household.dart';
import 'package:chore_bounty_application/models/household_member.dart';
import 'package:chore_bounty_application/models/leaderboard_entry.dart';
import 'package:chore_bounty_application/screens/auth_gate.dart';
import 'package:chore_bounty_application/screens/home_shell.dart';
import 'package:chore_bounty_application/screens/welcome_screen.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_filter_pills.dart';
import 'package:chore_bounty_application/widgets/leaderboard/leaderboard_podium.dart';
import 'package:chore_bounty_application/services/auth_service.dart';
import 'package:chore_bounty_application/services/bounty_service.dart';
import 'package:chore_bounty_application/services/household_service.dart';
import 'package:chore_bounty_application/widgets/bounty_detail/creator_action_bar.dart';
import 'package:chore_bounty_application/widgets/dialogs/congratulations_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bounty model F2/B-02 state & UTC conversion', () {
    test('canEdit, canCancel, and canDelete match all 6 chore states', () {
      final future = DateTime.now().add(const Duration(days: 1));
      final past = DateTime.now().subtract(const Duration(hours: 2));

      final available = Bounty(
        id: '1',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Open chore',
        status: 'open',
        dueAt: future,
      );
      expect(available.canEdit, isTrue);
      expect(available.canCancel, isTrue);
      expect(available.canDelete, isTrue);

      final taken = Bounty(
        id: '2',
        creatorId: '1',
        creator: 'Sheldon',
        assigneeId: '2',
        assignee: 'Leonard',
        title: 'Taken chore',
        status: 'claimed',
        dueAt: future,
      );
      expect(taken.canEdit, isTrue);
      expect(taken.canCancel, isTrue);
      expect(taken.canDelete, isFalse);

      final pending = Bounty(
        id: '3',
        creatorId: '1',
        creator: 'Sheldon',
        assigneeId: '2',
        assignee: 'Leonard',
        title: 'Submitted chore',
        status: 'submitted',
        dueAt: future,
      );
      expect(pending.canEdit, isFalse);
      expect(pending.canCancel, isFalse);
      expect(pending.canDelete, isFalse);

      final completed = Bounty(
        id: '4',
        creatorId: '1',
        creator: 'Sheldon',
        assigneeId: '2',
        assignee: 'Leonard',
        title: 'Done chore',
        status: 'completed',
        dueAt: future,
      );
      expect(completed.canEdit, isFalse);
      expect(completed.canCancel, isFalse);
      expect(completed.canDelete, isFalse);

      final cancelled = Bounty(
        id: '5',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Cancelled chore',
        status: 'cancelled',
        dueAt: future,
      );
      expect(cancelled.canEdit, isFalse);
      expect(cancelled.canCancel, isFalse);
      expect(cancelled.canDelete, isTrue);

      final expired = Bounty(
        id: '6',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Expired chore',
        status: 'open',
        dueAt: past,
      );
      expect(expired.isExpired, isTrue);
      expect(expired.canEdit, isFalse);
      expect(expired.canCancel, isFalse);
      expect(expired.canDelete, isTrue);
    });

    test('parses due_at UTC ISO timestamps into local DateTime', () {
      final bounty = Bounty.fromJson({
        'id': 9,
        'creator_id': 1,
        'title': 'Check UTC',
        'status': 'open',
        'due_at': '2026-11-15T12:00:00Z',
        'created_at': '2026-11-15T08:00:00Z',
      });

      expect(bounty.dueAt, isNotNull);
      expect(bounty.dueAt!.isUtc, isFalse);
      expect(bounty.createdAt, isNotNull);
      expect(bounty.createdAt!.isUtc, isFalse);
    });
  });

  group('CreatorActionBar F2 button matrix', () {
    Widget wrap(Bounty bounty) {
      return MaterialApp(
        home: Scaffold(
          body: CreatorActionBar(
            bounty: bounty,
            onEdit: () {},
            onCancel: () {},
            onDelete: () {},
          ),
        ),
      );
    }

    testWidgets('shows Edit + Delete for Available', (tester) async {
      await tester.pumpWidget(
        wrap(
          Bounty(
            id: '1',
            creatorId: '1',
            creator: 'Sheldon',
            title: 'Sweep',
            status: 'open',
            dueAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('shows Edit + Cancel for Taken', (tester) async {
      await tester.pumpWidget(
        wrap(
          Bounty(
            id: '2',
            creatorId: '1',
            creator: 'Sheldon',
            assigneeId: '2',
            title: 'Mop',
            status: 'claimed',
            dueAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('shows Delete only for Cancelled and Expired', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Bounty(
            id: '3',
            creatorId: '1',
            creator: 'Sheldon',
            title: 'Cancelled',
            status: 'cancelled',
          ),
        ),
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Cancel'), findsNothing);

      await tester.pumpWidget(
        wrap(
          Bounty(
            id: '4',
            creatorId: '1',
            creator: 'Sheldon',
            title: 'Expired',
            status: 'open',
            dueAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ),
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('F1 CongratulationsDialog & HomeShell celebration trigger', () {
    testWidgets('renders single approval, multi-approval summary, and triggers callbacks', (
      tester,
    ) async {
      var viewLeaderboardTapped = false;
      var closedTapped = false;

      final single = AppNotification(
        id: '101',
        bountyId: '12',
        bountyTitle: 'Take out trash',
        tokens: 25,
        householdId: '1',
        eventName: 'Chore Approved',
        description: 'Sheldon approved "Take out trash". +25 Tokens earned!',
        category: 'approved',
        actorName: 'Sheldon Cooper',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CongratulationsDialog(
              approvals: [single],
              onViewLeaderboard: () => viewLeaderboardTapped = true,
              onClose: () => closedTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Congratulations!'), findsOneWidget);
      expect(find.text('Your chore "Take out trash" was approved.'), findsOneWidget);
      expect(find.text('+25 Tokens'), findsOneWidget);
      expect(find.text('Approved by Sheldon Cooper'), findsOneWidget);

      await tester.tap(find.text('View Leaderboard'));
      expect(viewLeaderboardTapped, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CongratulationsDialog(
              approvals: [
                single,
                AppNotification(
                  id: '102',
                  bountyId: '13',
                  bountyTitle: 'Wash dishes',
                  tokens: 40,
                  householdId: '1',
                  eventName: 'Chore Approved',
                  description: 'Approved',
                  category: 'approved',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
                AppNotification(
                  id: '103',
                  bountyId: '14',
                  bountyTitle: 'Vacuum rug',
                  tokens: 15,
                  householdId: '1',
                  eventName: 'Chore Approved',
                  description: 'Approved',
                  category: 'approved',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
              ],
              onClose: () => closedTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 chores approved'), findsOneWidget);
      expect(find.text('• Take out trash'), findsOneWidget);
      expect(find.text('• Wash dishes'), findsOneWidget);
      expect(find.text('• Vacuum rug'), findsOneWidget);
      expect(find.text('+80 Tokens'), findsOneWidget);

      await tester.tap(find.text('Close'));
      expect(closedTapped, isTrue);
    });

    testWidgets(
      'HomeShell shows CongratulationsDialog once for numeric unread approved notification and ignores non-numeric derived ids',
      (tester) async {
        const user = AppUser(
          id: 2,
          name: 'Leonard Hofstadter',
          email: 'leonard@gmail.com',
        );
        const household = Household(
          id: 1,
          name: 'Apartment 4A',
          inviteCode: 'APT4A',
          createdBy: 1,
          role: 'member',
          membersCount: 2,
        );

        final fakeBounties = _FakeCelebrationBountyService([
          AppNotification(
            id: 'bounty_10_completed',
            bountyId: '10',
            householdId: '1',
            eventName: 'Chore Completed',
            description: 'Derived completion should be ignored',
            eventType: 'approved',
            category: 'approved',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: '55',
            bountyId: '11',
            bountyTitle: 'Scrub sink',
            tokens: 30,
            householdId: '1',
            eventName: 'Chore Approved',
            description: 'Sheldon approved "Scrub sink". +30 Tokens earned!',
            eventType: 'approved',
            category: 'approved',
            actorName: 'Sheldon Cooper',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        ]);

        final storage = _MemoryTokenStorage();
        final api = ApiClient(storage);

        await tester.pumpWidget(
          MaterialApp(
            home: HomeShell(
              user: user,
              auth: AuthService(api, storage),
              bounties: fakeBounties,
              households: _FakeSimpleHouseholdService([household]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Congratulations!'), findsOneWidget);
        expect(find.text('Your chore "Scrub sink" was approved.'), findsOneWidget);
        expect(find.text('+30 Tokens'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.text('Congratulations!'), findsNothing);
        expect(fakeBounties.markedReadIds, ['55']);
      },
    );
  });

  group('F3 LeaderboardView minimalist redesign', () {
    testWidgets('hides crowns, supports period switch, formats zero-token dash, and highlights current user', (
      tester,
    ) async {
      String? selectedPeriod;
      const currentUser = AppUser(
        id: 2,
        name: 'Leonard Hofstadter',
        email: 'leonard@gmail.com',
      );
      const household = Household(
        id: 1,
        name: 'Apartment 4A',
        inviteCode: 'APT4A',
        createdBy: 1,
        role: 'member',
        membersCount: 3,
      );
      const entries = [
        LeaderboardEntry(
          rank: 1,
          userId: 1,
          name: 'Sheldon Cooper',
          completedCount: 3,
          activeCount: 1,
          totalTokens: 150,
          totalRewardValue: 150,
          tier: 'Household Novice',
        ),
        LeaderboardEntry(
          rank: 2,
          userId: 2,
          name: 'Leonard Hofstadter',
          completedCount: 1,
          activeCount: 1,
          totalTokens: 50,
          totalRewardValue: 50,
          tier: 'Household Novice',
        ),
        LeaderboardEntry(
          rank: 3,
          userId: 3,
          name: 'Raj Koothrappali',
          completedCount: 0,
          activeCount: 0,
          totalTokens: 0,
          totalRewardValue: 0,
          tier: 'Household Novice',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardView(
            currentUser: currentUser,
            currentHousehold: household,
            leaderboard: entries,
            isLoading: false,
            onRefresh: () async {},
            onMenuTap: () {},
            onUserTap: (_) {},
            period: 'all',
            onPeriodChanged: (p) => selectedPeriod = p,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apartment 4A · 3 members'), findsOneWidget);
      expect(find.byType(DashboardFilterPills), findsOneWidget);
      expect(find.byType(LeaderboardPodiumSection), findsOneWidget);
      expect(find.text('–'), findsNWidgets(2));
      expect(find.text('You'), findsOneWidget);
      expect(find.textContaining('behind'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('TOKENS EARNED'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);

      final ownMaterial = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.color == const Color(0xFFF0FDF4));
      expect(ownMaterial.length, 2);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(selectedPeriod, 'week');
    });
  });

  group('B-03 AuthGate offline resilience', () {
    testWidgets('keeps token and renders Retry on network DioException', (tester) async {
      final storage = _MemoryTokenStorage(initialToken: 'saved-jwt');
      final api = ApiClient(storage);
      final auth = _FakeAuthService(
        api,
        storage,
        errorToThrow: DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionError,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            auth: auth,
            bounties: BountyService(api),
            households: HouseholdService(api),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to connect'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(await storage.read(), 'saved-jwt');
    });

    testWidgets('clears token on HTTP 401 and routes to WelcomeScreen', (tester) async {
      final storage = _MemoryTokenStorage(initialToken: 'expired-jwt');
      final api = ApiClient(storage);
      final auth = _FakeAuthService(
        api,
        storage,
        errorToThrow: DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 401,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            auth: auth,
            bounties: BountyService(api),
            households: HouseholdService(api),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(await storage.read(), isNull);
      expect(find.text('Unable to connect'), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({String? initialToken}) : _token = initialToken;

  String? _token;
  String? _householdId;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;

  @override
  Future<String?> readHouseholdId() async => _householdId;

  @override
  Future<void> saveHouseholdId(String id) async => _householdId = id;

  @override
  Future<String?> readAvatar() async => null;
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(
    super.api,
    super.storage, {
    this.errorToThrow,
  });

  final DioException? errorToThrow;

  @override
  Future<AppUser> me() async {
    if (errorToThrow != null) throw errorToThrow!;
    return const AppUser(id: 1, name: 'Test User', email: 'test@example.com');
  }
}

class _FakeSimpleHouseholdService extends HouseholdService {
  _FakeSimpleHouseholdService(this._list) : super(ApiClient(_MemoryTokenStorage()));

  final List<Household> _list;

  @override
  Future<List<Household>> all() async => _list;

  @override
  Future<List<HouseholdMember>> members(int householdId) async => const [];
}

class _FakeCelebrationBountyService extends BountyService {
  _FakeCelebrationBountyService(this._notifications)
      : super(ApiClient(_MemoryTokenStorage()));

  final List<AppNotification> _notifications;
  final List<String> markedReadIds = [];

  @override
  Future<List<Bounty>> all({
    String? status,
    String? householdId,
    int perPage = 100,
  }) async => const [];

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? householdId,
    String? period,
  }) async => const [];

  @override
  Future<List<AppNotification>> notifications({
    String? householdId,
    String? currentUserId,
    String? currentUserName,
    List<Bounty> fallbackBounties = const [],
  }) async =>
      _notifications;

  @override
  Future<bool> markNotificationRead(String id) async {
    markedReadIds.add(id);
    return true;
  }
}
