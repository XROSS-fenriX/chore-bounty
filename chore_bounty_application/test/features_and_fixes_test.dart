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
import 'package:chore_bounty_application/screens/household_prompt_screen.dart';
import 'package:chore_bounty_application/screens/login_screen.dart';
import 'package:chore_bounty_application/screens/register_screen.dart';
import 'package:chore_bounty_application/screens/welcome_screen.dart';
import 'package:chore_bounty_application/widgets/bounty_form/bounty_category_icons.dart';
import 'package:chore_bounty_application/widgets/bounty_form/bounty_date_time_picker.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_bounty_card.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_filter_pills.dart';
import 'package:chore_bounty_application/widgets/leaderboard/leaderboard_podium.dart';
import 'package:chore_bounty_application/services/auth_service.dart';
import 'package:chore_bounty_application/services/bounty_service.dart';
import 'package:chore_bounty_application/services/household_service.dart';
import 'package:chore_bounty_application/widgets/bounty_detail/bounty_status_chip.dart';
import 'package:chore_bounty_application/widgets/bounty_detail/creator_action_bar.dart';
import 'package:chore_bounty_application/widgets/dialogs/congratulations_dialog.dart';
import 'package:chore_bounty_application/widgets/ui.dart';
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

      expect(find.text('Apartment 4A · 3 members'), findsNothing);
      expect(find.byType(DashboardFilterPills), findsOneWidget);
      expect(find.byType(LeaderboardPodiumSection), findsOneWidget);
      expect(find.text('–'), findsNWidgets(2));
      expect(find.text('You'), findsOneWidget);
      expect(find.textContaining('behind'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('TOKENS EARNED'), findsNothing);
      expect(find.text('CHORES DONE'), findsNothing);
      expect(find.text('IN PROGRESS'), findsNothing);
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

  group('ProfileView compact preview & scalability', () {
    testWidgets('caps Chore Activity and My Households at 3 inline items and opens View all sheets for overflow', (
      tester,
    ) async {
      const user = AppUser(
        id: 1,
        name: 'Leonard Hofstadter',
        email: 'leonard@gmail.com',
      );
      final households = List.generate(
        5,
        (i) => Household(
          id: i + 1,
          name: 'Home ${i + 1}',
          inviteCode: 'CODE0${i + 1}',
          createdBy: 1,
          role: i == 0 ? 'owner' : 'member',
          membersCount: i + 2,
        ),
      );
      final activeHousehold = households[2]; // "Home 3" should sort first
      final bounties = List.generate(
        6,
        (i) => Bounty(
          id: '${i + 10}',
          householdId: '3',
          creatorId: '2',
          creator: 'Sheldon Cooper',
          assigneeId: '1',
          assignee: 'Leonard Hofstadter',
          title: 'Chore Item ${i + 1}',
          category: 'Cleaning',
          points: 20,
          status: 'completed',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileView(
              currentUser: user,
              currentHousehold: activeHousehold,
              myHouseholds: households,
              bounties: bounties,
              onRefresh: () async {},
              onEditProfile: () {},
              onSelectBounty: (_) {},
              onAddHousehold: () {},
              onSwitchHousehold: (_) {},
              onLeaveHousehold: (_) {},
              onLogout: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chore Activity caps inline list at 3 items + shows View all 6 chores
      expect(find.text('Chore Item 1'), findsOneWidget);
      expect(find.text('Chore Item 3'), findsOneWidget);
      expect(find.text('Chore Item 4'), findsNothing);
      expect(find.text('View all 6 chores'), findsOneWidget);

      await tester.ensureVisible(find.text('View all 6 chores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all 6 chores'));
      await tester.pumpAndSettle();
      final choreSheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: choreSheet, matching: find.text('Chore Item 4')),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(of: choreSheet, matching: find.byType(TextField)),
        'Item 6',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: choreSheet, matching: find.text('Chore Item 6')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: choreSheet, matching: find.text('Chore Item 1')),
        findsNothing,
      );

      // Close Chore Activity sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Scroll to My Households: active ("Home 3") + 2 others (max 3 inline), plus View all 5 households
      final profileScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('View all 5 households'),
        250,
        scrollable: profileScrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Home 3'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Home 4'), findsNothing);
      expect(find.text('View all 5 households'), findsOneWidget);

      await tester.ensureVisible(find.text('View all 5 households'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all 5 households'));
      await tester.pumpAndSettle();
      final householdSheet = find.byType(BottomSheet);
      expect(find.text('My Households (5)'), findsOneWidget);
      await tester.enterText(
        find.descendant(of: householdSheet, matching: find.byType(TextField)),
        'Home 5',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.descendant(of: householdSheet, matching: find.byType(ListView)),
          matching: find.text('Home 5'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: householdSheet, matching: find.text('Home 3')),
        findsNothing,
      );
    });
  });

  group('CreateBounty future due date & time restriction', () {
    testWidgets('BountyDateTimePicker rejects past time on today and accepts future time', (
      tester,
    ) async {
      DateTime? pickedDate;
      String? invalidMessage;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BountyDateTimePicker(
                  selectedDate: pickedDate,
                  errorText: invalidMessage,
                  onChanged: (dt) => setState(() {
                    pickedDate = dt;
                    invalidMessage = null;
                  }),
                  onInvalidSelection: (msg) => setState(() {
                    invalidMessage = msg;
                  }),
                );
              },
            ),
          ),
        ),
      );

      // 1. Open date picker -> pick today (OK) -> switch time picker to input and enter 00:00 (past)
      await tester.tap(find.text('Select date and time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final timeInputs = find.byType(TextFormField);
      await tester.enterText(timeInputs.at(0), '00');
      await tester.enterText(timeInputs.at(1), '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(pickedDate, isNull);
      expect(find.text(BountyDateTimePicker.futureErrorMessage), findsOneWidget);

      // 2. Pick tomorrow -> enter 12:00 -> accepted and clears error
      final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
      await tester.tap(find.text('Select date and time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        '${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.year}',
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final tomorrowInputs = find.byType(TextFormField);
      await tester.enterText(tomorrowInputs.at(0), '12');
      await tester.enterText(tomorrowInputs.at(1), '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(pickedDate, isNotNull);
      expect(pickedDate!.isAfter(DateTime.now()), isTrue);
      expect(find.text(BountyDateTimePicker.futureErrorMessage), findsNothing);
    });

    testWidgets('CreateBounty prevents submitting past due date and accepts future date/time', (
      tester,
    ) async {
      final fakeService = _FakeCreateBountyService();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
          home: CreateBounty(
            service: fakeService,
            currentHouseholdId: 1,
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'Clean fridge',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final dueFinder = find.text('Select date and time');
      await tester.scrollUntilVisible(
        dueFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(dueFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final pastTimeInputs = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(pastTimeInputs.at(0), '00');
      await tester.enterText(pastTimeInputs.at(1), '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(BountyDateTimePicker),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text(BountyDateTimePicker.futureErrorMessage), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Post Chore'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post Chore'));
      await tester.pumpAndSettle();

      expect(fakeService.createCalls, 0);

      // Selecting a valid future date & time clears the error and allows submission
      final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
      await tester.scrollUntilVisible(
        dueFinder,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(dueFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextFormField),
        ).first,
        '${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.year}',
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final tomorrowInputs = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(tomorrowInputs.at(0), '12');
      await tester.enterText(tomorrowInputs.at(1), '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text(BountyDateTimePicker.futureErrorMessage), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Post Chore'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post Chore'));
      await tester.pumpAndSettle();

      expect(fakeService.createCalls, 1);
      final dueAtRaw = fakeService.lastCreatedPayload?['due_at'] as String?;
      expect(dueAtRaw, isNotNull);
      expect(DateTime.parse(dueAtRaw!).isAfter(DateTime.now()), isTrue);
    });
  });

  group('DashboardBountyCard asset icons', () {
    testWidgets('uses CategoryIconWidget PNGs from assets/images/icons including living room chores', (
      tester,
    ) async {
      final chores = [
        const Bounty(
          id: '1',
          creatorId: '1',
          creator: 'Sheldon',
          title: 'Clean the living room',
          category: 'Cleaning',
          status: 'open',
        ),
        const Bounty(
          id: '2',
          creatorId: '1',
          creator: 'Sheldon',
          title: 'Take out the trash',
          category: 'Cleaning',
          status: 'open',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final chore in chores)
                  DashboardBountyCard(
                    bounty: chore,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CategoryIconWidget), findsNWidgets(2));
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final iconPaths = images
          .map((img) {
            final provider = img.image;
            return provider is ResizeImage ? provider.imageProvider : provider;
          })
          .whereType<AssetImage>()
          .map((asset) => asset.assetName)
          .toList();
      expect(iconPaths, contains('assets/images/icons/clean_icon.png'));
      expect(iconPaths, contains('assets/images/icons/trash_bin_icon.png'));
    });
  });

  group('Minimalist auth screens & responsive layouts', () {
    testWidgets('WelcomeScreen renders on compact viewport and navigates cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _MemoryTokenStorage();
      final api = ApiClient(storage);
      final auth = _FakeAuthService(api, storage);

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            auth: auth,
            bounties: _FakeCreateBountyService(),
            households: _FakeSimpleHouseholdService(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Turn Chores Into Bounties'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(BrandMark), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(BrandMark), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

      await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign In'));
      await tester.tap(find.widgetWithText(TextButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('LoginScreen validates inline, toggles password visibility, and signs in', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _MemoryTokenStorage();
      final api = ApiClient(storage);
      final auth = _FakeAuthService(api, storage);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            auth: auth,
            bounties: _FakeCreateBountyService(),
            households: _FakeSimpleHouseholdService(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'leonard@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();
      expect(find.text('Please enter your password.'), findsOneWidget);

      final passwordFieldFinder = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isFalse);

      await tester.enterText(passwordFieldFinder, 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(auth.lastLoginEmail, 'leonard@example.com');
      expect(find.byType(HouseholdPromptScreen), findsOneWidget);
    });

    testWidgets('RegisterScreen adapts cleanly from 320px to 412px and registers user', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _MemoryTokenStorage();
      final api = ApiClient(storage);
      final auth = _FakeAuthService(api, storage);

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(
            auth: auth,
            bounties: _FakeCreateBountyService(),
            households: _FakeSimpleHouseholdService(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(412, 915);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Leonard');
      await tester.enterText(fields.at(1), 'Hofstadter');

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      await tester.enterText(fields.at(3), 'leonard@example.com');
      await tester.enterText(fields.at(4), 'password123');
      await tester.enterText(fields.at(5), 'password123');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(auth.lastRegisteredEmail, 'leonard@example.com');
      expect(auth.lastRegisteredGender, 'male');
      expect(find.byType(HouseholdPromptScreen), findsOneWidget);
    });
  });

  group('Submitted notifications restricted to chore poster', () {
    test('deriveFromBounties only exposes submitted notification to bounty creator', () {
      const bounties = [
        Bounty(
          id: '10',
          householdId: '1',
          creatorId: '2',
          creator: 'Leonard Hofstadter',
          assigneeId: '3',
          assignee: 'Penelophe Hofstadter',
          title: 'Buy water',
          points: 10,
          status: 'submitted',
        ),
        Bounty(
          id: '11',
          householdId: '1',
          creatorId: '1',
          creator: 'Sheldon Cooper',
          assigneeId: '2',
          assignee: 'Leonard Hofstadter',
          title: 'Clean the living room',
          points: 50,
          status: 'submitted',
        ),
      ];

      final sheldonNotifs = AppNotification.deriveFromBounties(
        bounties,
        currentUserId: '1',
        currentUserName: 'Sheldon Cooper',
      );
      expect(sheldonNotifs.length, 1);
      expect(sheldonNotifs.first.bountyId, '11');

      final pennyNotifs = AppNotification.deriveFromBounties(
        bounties,
        currentUserId: '3',
        currentUserName: 'Penelophe Hofstadter',
      );
      expect(pennyNotifs, isEmpty);
    });

    testWidgets('NotificationsScreen hides submitted notifications for chores posted by other roommates', (tester) async {
      const sheldon = AppUser(
        id: 1,
        name: 'Sheldon Cooper',
        email: 'sheldon@example.com',
      );
      final notifications = [
        AppNotification.fromJson({
          'id': 101,
          'household_id': 1,
          'bounty_id': 10,
          'user_id': 1,
          'actor_id': 3,
          'actor_name': 'Penelophe Hofstadter',
          'event_type': 'submitted',
          'event_name': 'Chore Submitted',
          'description': 'Penelophe Hofstadter submitted "Buy water" for approval.',
          'bounty': {'id': 10, 'creator_id': 2, 'title': 'Buy water', 'tokens': 10},
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        }),
        AppNotification.fromJson({
          'id': 102,
          'household_id': 1,
          'bounty_id': 11,
          'user_id': 1,
          'actor_id': 2,
          'actor_name': 'Leonard Hofstadter',
          'event_type': 'submitted',
          'event_name': 'Chore Submitted',
          'description': 'Leonard Hofstadter submitted "Clean the living room" for approval.',
          'bounty': {'id': 11, 'creator_id': 1, 'title': 'Clean the living room', 'tokens': 50},
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        }),
        AppNotification.fromJson({
          'id': 103,
          'household_id': 1,
          'bounty_id': 10,
          'user_id': 1,
          'actor_id': 3,
          'actor_name': 'Penelophe Hofstadter',
          'event_type': 'claimed',
          'event_name': 'Chore Claimed',
          'description': 'Penelophe Hofstadter claimed "Buy water".',
          'bounty': {'id': 10, 'creator_id': 2, 'title': 'Buy water', 'tokens': 10},
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        }),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            user: sheldon,
            bounties: _FakeCreateBountyService(),
            initialNotifications: notifications,
            onSelectBounty: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Penelophe Hofstadter submitted "Buy water" for approval.'),
        findsNothing,
      );
      expect(
        find.text('Leonard Hofstadter submitted "Clean the living room" for approval.'),
        findsOneWidget,
      );
      expect(
        find.text('Penelophe Hofstadter claimed "Buy water".'),
        findsOneWidget,
      );
    });
  });

  group('Awaiting Review chore state', () {
    testWidgets('shows Awaiting Review across model, BountyStatusChip, DashboardBountyCard, and ChoresView filter', (tester) async {
      const user = AppUser(
        id: 1,
        name: 'Sheldon Cooper',
        email: 'sheldon@example.com',
      );
      const claimed = Bounty(
        id: '201',
        householdId: '1',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        assigneeId: '2',
        assignee: 'Leonard Hofstadter',
        title: 'Take out trash',
        points: 20,
        status: 'claimed',
      );
      const awaiting = Bounty(
        id: '202',
        householdId: '1',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        assigneeId: '2',
        assignee: 'Leonard Hofstadter',
        title: 'Mop kitchen floor',
        points: 35,
        status: 'submitted',
        submissionProof: 'Floor is clean.',
      );

      expect(claimed.statusLabel, 'Taken');
      expect(awaiting.statusLabel, 'Awaiting Review');
      expect(awaiting.isAwaitingReview, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const BountyStatusChip(bounty: awaiting),
                  DashboardBountyCard(
                    bounty: claimed,
                    currentUserId: '1',
                    currentUserName: 'Sheldon Cooper',
                    onTap: () {},
                  ),
                  DashboardBountyCard(
                    bounty: awaiting,
                    currentUserId: '1',
                    currentUserName: 'Sheldon Cooper',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Awaiting Review'), findsNWidgets(2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChoresView(
              bounties: const [claimed, awaiting],
              user: user,
              isLoading: false,
              onRefresh: () async {},
              onSelectBounty: (_) {},
              onCreateBounty: () {},
              onMenuTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Posted by Me').last);
      await tester.pumpAndSettle();

      expect(find.text('Awaiting Review'), findsWidgets);

      final filterPill = find.descendant(
        of: find.byType(DashboardFilterPills),
        matching: find.text('Awaiting Review'),
      );
      await tester.ensureVisible(filterPill);
      await tester.tap(filterPill);
      await tester.pumpAndSettle();

      expect(find.text('Take out trash'), findsNothing);
      expect(find.text('Mop kitchen floor'), findsWidgets);

      final takenPill = find.descendant(
        of: find.byType(DashboardFilterPills),
        matching: find.text('Taken'),
      );
      await tester.ensureVisible(takenPill);
      await tester.tap(takenPill);
      await tester.pumpAndSettle();

      expect(find.text('Take out trash'), findsOneWidget);
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
  String? lastLoginEmail;
  String? lastRegisteredEmail;
  String? lastRegisteredGender;

  @override
  Future<AppUser> me() async {
    if (errorToThrow != null) throw errorToThrow!;
    return const AppUser(id: 1, name: 'Test User', email: 'test@example.com');
  }

  @override
  Future<AppUser> login(String email, String password) async {
    lastLoginEmail = email;
    return AppUser(id: 1, name: 'Leonard Hofstadter', email: email);
  }

  @override
  Future<AppUser> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String gender,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    lastRegisteredEmail = email;
    lastRegisteredGender = gender;
    return AppUser(
      id: 1,
      name: '$firstName $lastName',
      email: email,
      gender: gender,
    );
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

class _FakeCreateBountyService extends BountyService {
  _FakeCreateBountyService() : super(ApiClient(_MemoryTokenStorage()));

  int createCalls = 0;
  Map<String, dynamic>? lastCreatedPayload;

  @override
  Future<void> create(Map<String, dynamic> data) async {
    createCalls++;
    lastCreatedPayload = data;
  }
}
