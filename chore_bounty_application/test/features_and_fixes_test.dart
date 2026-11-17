import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chore_bounty_application/core/api_client.dart';
import 'package:chore_bounty_application/core/token_storage.dart';
import 'package:chore_bounty_application/models/app_notification.dart';
import 'package:chore_bounty_application/models/app_user.dart';
import 'package:chore_bounty_application/models/bounty.dart';
import 'package:chore_bounty_application/models/household.dart';
import 'package:chore_bounty_application/models/household_member.dart';
import 'package:chore_bounty_application/models/leaderboard_entry.dart';
import 'package:chore_bounty_application/screens/auth_gate.dart';
import 'package:chore_bounty_application/screens/change_password_screen.dart';
import 'package:chore_bounty_application/screens/home_shell.dart';
import 'package:chore_bounty_application/screens/household_prompt_screen.dart';
import 'package:chore_bounty_application/screens/login_screen.dart';
import 'package:chore_bounty_application/screens/register_screen.dart';
import 'package:chore_bounty_application/screens/welcome_screen.dart';
import 'package:chore_bounty_application/widgets/bounty_form/bounty_category_icons.dart';
import 'package:chore_bounty_application/widgets/bounty_form/bounty_date_time_picker.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_bounty_card.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_header.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_filter_pills.dart';
import 'package:chore_bounty_application/widgets/leaderboard/leaderboard_podium.dart';
import 'package:chore_bounty_application/services/auth_service.dart';
import 'package:chore_bounty_application/services/bounty_service.dart';
import 'package:chore_bounty_application/services/household_service.dart';
import 'package:chore_bounty_application/widgets/bounty_detail/bounty_status_chip.dart';
import 'package:chore_bounty_application/widgets/bounty_detail/bounty_proof_gallery.dart';
import 'package:chore_bounty_application/widgets/bounty_detail/creator_action_bar.dart';
import 'package:chore_bounty_application/widgets/dialogs/congratulations_dialog.dart';
import 'package:chore_bounty_application/widgets/dialogs/redo_requested_dialog.dart';
import 'package:chore_bounty_application/widgets/ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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

      // 1. Open date picker -> pick today explicitly -> switch time picker to input and enter 00:00 (past)
      final today = DateUtils.dateOnly(DateTime.now());
      await tester.tap(find.text('Select date and time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        '${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}/${today.year}',
      );
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
      final todayForCreate = DateUtils.dateOnly(DateTime.now());
      await tester.tap(dueFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextFormField),
        ).first,
        '${todayForCreate.month.toString().padLeft(2, '0')}/${todayForCreate.day.toString().padLeft(2, '0')}/${todayForCreate.year}',
      );
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

  group('BountyService pagination & ApiClient GET retry', () {
    test('BountyService.all aggregates paginated responses without duplicates', () async {
      final api = ApiClient(_MemoryTokenStorage());
      final requestedPages = <String>[];
      api.dio.httpClientAdapter = _StubHttpAdapter((options) async {
        final page = options.queryParameters['page']?.toString() ?? '1';
        requestedPages.add(page);
        final items = page == '1'
            ? [
                {'id': 1, 'title': 'Sweep floor', 'creator_id': 1, 'status': 'open'},
                {'id': 2, 'title': 'Mop floor', 'creator_id': 1, 'status': 'open'},
              ]
            : [
                {'id': 2, 'title': 'Mop floor', 'creator_id': 1, 'status': 'open'},
                {'id': 3, 'title': 'Wash dishes', 'creator_id': 1, 'status': 'open'},
              ];

        return ResponseBody.fromString(
          jsonEncode({
            'data': items,
            'meta': {'current_page': int.parse(page), 'last_page': 2},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final service = BountyService(api);
      final bounties = await service.all(perPage: 2);

      expect(requestedPages, ['1', '2']);
      expect(bounties.map((b) => b.id).toList(), ['1', '2', '3']);
    });

    test('ApiClient retries idempotent GET once after transient FormatException', () async {
      final api = ApiClient(_MemoryTokenStorage());
      var attempts = 0;
      api.dio.httpClientAdapter = _StubHttpAdapter((options) async {
        attempts++;
        if (attempts == 1) {
          return ResponseBody.fromString(
            '{"data":[{"id":1,"title":"Corrupted',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {'id': 1, 'title': 'Recovered Chore', 'creator_id': 1, 'status': 'open'},
            ],
            'meta': {'current_page': 1, 'last_page': 1},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final service = BountyService(api);
      final bounties = await service.all();

      expect(attempts, 2);
      expect(bounties.length, 1);
      expect(bounties.first.title, 'Recovered Chore');
    });
  });

  group('Dashboard limit, See more redirect, and Chores pagination', () {
    testWidgets(
      'DashboardView caps rendered chores to 5 and replaces + Post with See more redirecting to Chores Page',
      (tester) async {
        const user = AppUser(id: 1, name: 'Sheldon Cooper', email: 's@test.com');
        final bounties = List<Bounty>.generate(
          8,
          (i) => Bounty(
            id: '${i + 1}',
            creatorId: '2',
            creator: 'Leonard',
            title: 'Dashboard Chore ${i + 1}',
            status: 'open',
            points: 10,
          ),
        );

        var redirectedToChores = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardView(
                user: user,
                bounties: bounties,
                leaderboard: const [],
                isLoading: false,
                onRefresh: () async {},
                onSelectBounty: (_) {},
                onCreateBounty: () {},
                onViewChores: () => redirectedToChores = true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(DashboardBountyCard), findsNWidgets(5));
        expect(find.text('Dashboard Chore 5'), findsOneWidget);
        expect(find.text('Dashboard Chore 6'), findsNothing);
        expect(find.text('8'), findsOneWidget);
        expect(find.text('Post'), findsNothing);
        expect(find.text('See more'), findsOneWidget);

        await tester.tap(find.text('See more'));
        await tester.pump();
        expect(redirectedToChores, isTrue);
      },
    );

    testWidgets('ChoresView paginates chore list to 5 items per page', (
      tester,
    ) async {
      const user = AppUser(id: 1, name: 'Sheldon Cooper', email: 's@test.com');
      final bounties = List<Bounty>.generate(
        12,
        (i) => Bounty(
          id: '${i + 1}',
          creatorId: '2',
          creator: 'Leonard',
          title: 'Chore Item ${i + 1}',
          status: 'open',
          points: 15,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChoresView(
              user: user,
              bounties: bounties,
              isLoading: false,
              onRefresh: () async {},
              onSelectBounty: (_) {},
              onCreateBounty: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DashboardBountyCard), findsNWidgets(5));
      expect(find.text('Chore Item 1'), findsOneWidget);
      expect(find.text('Chore Item 5'), findsOneWidget);
      expect(find.text('Chore Item 6'), findsNothing);
      expect(find.text('Showing 1–5 of 12'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final nextBtn = find.byTooltip('Next page');
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardBountyCard), findsNWidgets(5));
      expect(find.text('Chore Item 6'), findsOneWidget);
      expect(find.text('Chore Item 10'), findsOneWidget);
      expect(find.text('Chore Item 1'), findsNothing);
      expect(find.text('Showing 6–10 of 12'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardBountyCard), findsNWidgets(2));
      expect(find.text('Chore Item 11'), findsOneWidget);
      expect(find.text('Chore Item 12'), findsOneWidget);
      expect(find.text('Showing 11–12 of 12'), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Chore Item 12');
      await tester.pump();

      expect(find.byType(DashboardBountyCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DashboardBountyCard),
          matching: find.text('Chore Item 12'),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Next page'), findsNothing);
    });
  });

  group('Camera photo submission proof', () {
    test('Bounty.fromJson parses and normalizes submission_images URLs', () {
      final bounty = Bounty.fromJson({
        'id': 9,
        'title': 'Clean stove',
        'creator_id': 1,
        'status': 'submitted',
        'submission_proof': 'Done',
        'submission_images': [
          '/storage/bounty-proofs/2/9/photo1.jpg',
          'https://cdn.example.com/photo2.jpg',
        ],
      });

      expect(bounty.submissionImages.length, 2);
      expect(
        bounty.submissionImages.first,
        endsWith('/storage/bounty-proofs/2/9/photo1.jpg'),
      );
      expect(
        bounty.submissionImages.last,
        'https://cdn.example.com/photo2.jpg',
      );
    });

    testWidgets(
      'BountyDetailScreen allows submit without photos',
      (tester) async {
        const assignee = AppUser(
          id: 2,
          name: 'Amy Farrah Fowler',
          email: 'amy@example.com',
        );
        const claimed = Bounty(
          id: '41',
          householdId: '2',
          creatorId: '1',
          creator: 'Sheldon Cooper',
          assigneeId: '2',
          assignee: 'Amy Farrah Fowler',
          title: 'Take out recycling',
          status: 'claimed',
          points: 20,
        );

        final fakeService = _FakeSubmitBountyService();

        await tester.pumpWidget(
          MaterialApp(
            home: BountyDetailScreen(
              bounty: claimed,
              currentUser: assignee,
              service: fakeService,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Open Camera'), findsOneWidget);
        expect(find.text('0 / 3 Photos'), findsOneWidget);

        await tester.enterText(
          find.byType(TextField),
          'Bins emptied and relined',
        );
        await tester.tap(find.text('Submit for Review'));
        await tester.pumpAndSettle();

        expect(fakeService.submitCalls, 1);
        expect(fakeService.lastProof, 'Bins emptied and relined');
        expect(fakeService.lastImagePaths, isEmpty);
      },
    );

    testWidgets(
      'BountyDetailScreen optionally attaches and uploads camera/gallery photos',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('proof_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final pngBytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        );
        final samplePhoto = File('${tempDir.path}/proof.png')
          ..writeAsBytesSync(pngBytes);

        const assignee = AppUser(
          id: 2,
          name: 'Amy Farrah Fowler',
          email: 'amy@example.com',
        );
        const claimed = Bounty(
          id: '42',
          householdId: '2',
          creatorId: '1',
          creator: 'Sheldon Cooper',
          assigneeId: '2',
          assignee: 'Amy Farrah Fowler',
          title: 'Wipe kitchen counter',
          status: 'claimed',
          points: 30,
        );

        final fakeService = _FakeSubmitBountyService();
        ImageSource? requestedSource;

        await tester.pumpWidget(
          MaterialApp(
            home: BountyDetailScreen(
              bounty: claimed,
              currentUser: assignee,
              service: fakeService,
              pickProofImage: (source) async {
                requestedSource = source;
                return samplePhoto.path;
              },
            ),
          ),
        );
        await tester.pump();

        // Capturing photo via Open Camera attaches preview
        await tester.tap(find.text('Open Camera'));
        await tester.pumpAndSettle();

        expect(requestedSource, ImageSource.camera);
        expect(find.text('1 / 3 Photos'), findsOneWidget);

        // Removing photo clears preview
        await tester.tap(find.byTooltip('Remove photo 1'));
        await tester.pump();
        expect(find.text('0 / 3 Photos'), findsOneWidget);

        // Capture again, add note, and submit
        await tester.tap(find.text('Open Camera'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Cleaned stovetop and counter',
        );
        await tester.tap(find.text('Submit for Review'));
        await tester.pumpAndSettle();

        expect(fakeService.submitCalls, 1);
        expect(fakeService.lastProof, 'Cleaned stovetop and counter');
        expect(fakeService.lastImagePaths, [samplePhoto.path]);
      },
    );

    testWidgets(
      'BountyDetailScreen renders BountyProofGallery when submitted chore has submissionImages',
      (tester) async {
        const creator = AppUser(
          id: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@example.com',
        );
        const submitted = Bounty(
          id: '43',
          householdId: '2',
          creatorId: '1',
          creator: 'Sheldon Cooper',
          assigneeId: '2',
          assignee: 'Amy Farrah Fowler',
          title: 'Wipe kitchen counter',
          status: 'submitted',
          submissionProof: 'Counters spotless',
          submissionImages: ['https://example.com/proof1.jpg'],
          points: 30,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BountyDetailScreen(
              bounty: submitted,
              currentUser: creator,
              service: _FakeSubmitBountyService(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Proof Submitted'), findsOneWidget);
        expect(find.byType(BountyProofGallery), findsOneWidget);
        expect(find.text('Counters spotless'), findsOneWidget);
      },
    );
  });

  group('Security, notifications, household departure & dashboard metrics', () {
    test(
      'BountyService.notifications returns empty list on 200 [] without deriving fallback',
      () async {
        final storage = _MemoryTokenStorage(initialToken: 'token');
        final api = ApiClient(storage);
        api.dio.httpClientAdapter = _StubHttpAdapter((options) async {
          return ResponseBody.fromString(
            jsonEncode({'data': []}),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

        final service = BountyService(api);
        const fallback = [
          Bounty(
            id: '99',
            householdId: '10',
            creatorId: '2',
            creator: 'Leonard',
            title: 'Fallback Chore',
            status: 'open',
            points: 20,
          ),
        ];

        final result = await service.notifications(
          householdId: '10',
          currentUserId: '1',
          currentUserName: 'Sheldon',
          fallbackBounties: fallback,
        );

        expect(result, isEmpty);
      },
    );

    test(
      'AppNotification.isVisibleTo enforces userId and activeHouseholdId boundaries',
      () {
        final notif = AppNotification(
          id: '10',
          householdId: '5',
          userId: '1',
          actorId: '2',
          actorName: 'Leonard',
          eventType: 'posted',
          eventName: 'Chore Posted',
          description: 'New chore',
          createdAt: DateTime(2026, 1, 1),
        );

        expect(notif.isVisibleTo('1', 'Sheldon', '5'), isTrue);
        expect(notif.isVisibleTo('3', 'Penny', '5'), isFalse);
        expect(notif.isVisibleTo('1', 'Sheldon', '6'), isFalse);
      },
    );

    test(
      'Bounty.isVisibleForHousehold hides open/taken/submitted departed chores and retains other-member completed chores',
      () {
        const departedHouseholdIds = <String>{};

        const openDeparted = Bounty(
          id: '1',
          householdId: '10',
          creatorId: '2',
          title: 'Open Departed',
          status: 'open',
        );
        const takenDeparted = Bounty(
          id: '2',
          householdId: '10',
          creatorId: '2',
          assigneeId: '3',
          title: 'Taken Departed',
          status: 'claimed',
        );
        const reviewDeparted = Bounty(
          id: '3',
          householdId: '10',
          creatorId: '1',
          assigneeId: '3',
          title: 'Review Departed',
          status: 'submitted',
        );
        const completedBySelf = Bounty(
          id: '4',
          householdId: '10',
          creatorId: '2',
          assigneeId: '1',
          title: 'Completed By Me',
          status: 'completed',
        );
        const completedByOther = Bounty(
          id: '5',
          householdId: '10',
          creatorId: '2',
          assigneeId: '3',
          title: 'Completed By Penny',
          status: 'completed',
        );

        expect(
          openDeparted.isVisibleForHousehold(
            currentUserId: '1',
            memberHouseholdIds: departedHouseholdIds,
          ),
          isFalse,
        );
        expect(
          takenDeparted.isVisibleForHousehold(
            currentUserId: '1',
            memberHouseholdIds: departedHouseholdIds,
          ),
          isFalse,
        );
        expect(
          reviewDeparted.isVisibleForHousehold(
            currentUserId: '1',
            memberHouseholdIds: departedHouseholdIds,
          ),
          isFalse,
        );
        expect(
          completedBySelf.isVisibleForHousehold(
            currentUserId: '1',
            memberHouseholdIds: departedHouseholdIds,
          ),
          isFalse,
        );
        expect(
          completedByOther.isVisibleForHousehold(
            currentUserId: '1',
            memberHouseholdIds: departedHouseholdIds,
          ),
          isTrue,
        );

        // Rejoining restores non-completed visibility
        expect(
          openDeparted.isVisibleForHousehold(
            currentUserId: '1',
            memberHouseholdIds: const {'10'},
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'DashboardView preserves previous styling and enforces departure chore filtering',
      (tester) async {
        const user = AppUser(id: 1, name: 'Sheldon Cooper', email: 's@test.com');
        const currentHousehold = Household(
          id: 10,
          name: 'Apt 4A',
          inviteCode: 'APT4A1',
        );
        const leaderboard = [
          LeaderboardEntry(
            userId: 1,
            name: 'Sheldon Cooper',
            totalTokens: 120,
            completedCount: 3,
            activeCount: 1,
            totalRewardValue: 120.0,
            tier: 'Gold',
            rank: 1,
          ),
          LeaderboardEntry(
            userId: 2,
            name: 'Leonard Hofstadter',
            totalTokens: 80,
            completedCount: 2,
            activeCount: 0,
            totalRewardValue: 80.0,
            tier: 'Silver',
            rank: 2,
          ),
        ];

        const bounties = [
          Bounty(
            id: '1',
            householdId: '10',
            creatorId: '2',
            creator: 'Leonard',
            title: 'Active Open Kitchen',
            status: 'open',
            points: 30,
          ),
          Bounty(
            id: '2',
            householdId: '10',
            creatorId: '2',
            creator: 'Leonard',
            assigneeId: '1',
            assignee: 'Sheldon Cooper',
            title: 'Active Claimed Trash',
            status: 'claimed',
            points: 20,
          ),
          Bounty(
            id: '3',
            householdId: '10',
            creatorId: '2',
            creator: 'Leonard',
            assigneeId: '1',
            assignee: 'Sheldon Cooper',
            title: 'Active Completed Sweep',
            status: 'completed',
            points: 50,
          ),
          Bounty(
            id: '4',
            householdId: '99',
            creatorId: '4',
            creator: 'Howard',
            title: 'Departed Open Hidden',
            status: 'open',
            points: 40,
            isViewerActiveMember: false,
          ),
          Bounty(
            id: '5',
            householdId: '99',
            creatorId: '4',
            creator: 'Howard',
            assigneeId: '5',
            assignee: 'Raj',
            title: 'Departed Completed Retained',
            status: 'completed',
            points: 25,
            isViewerActiveMember: false,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardView(
                user: user,
                currentHousehold: currentHousehold,
                myHouseholds: const [currentHousehold],
                memberHouseholdIds: const {'10'},
                bounties: bounties,
                leaderboard: leaderboard,
                isLoading: false,
                onRefresh: () async {},
                onSelectBounty: (_) {},
                onCreateBounty: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('120'), findsOneWidget);
        expect(find.text('1 task ongoing'), findsOneWidget);
        expect(find.text('Rank #1 of 2'), findsNothing);
        expect(find.text('50% done'), findsNothing);

        expect(find.text('Active Open Kitchen'), findsOneWidget);
        expect(find.text('Departed Open Hidden'), findsNothing);
      },
    );

    testWidgets(
      'ChoresView and ProfileView retain only other-member completed chores for departed households',
      (tester) async {
        const user = AppUser(id: 1, name: 'Sheldon Cooper', email: 's@test.com');
        const departedBounties = [
          Bounty(
            id: '10',
            householdId: '50',
            creatorId: '2',
            creator: 'Leonard',
            title: 'Departed Open Dish',
            status: 'open',
            points: 15,
            isViewerActiveMember: false,
          ),
          Bounty(
            id: '11',
            householdId: '50',
            creatorId: '1',
            creator: 'Sheldon Cooper',
            assigneeId: '2',
            assignee: 'Leonard',
            title: 'Departed Review Dish',
            status: 'submitted',
            points: 20,
            isViewerActiveMember: false,
          ),
          Bounty(
            id: '12',
            householdId: '50',
            creatorId: '2',
            creator: 'Leonard',
            assigneeId: '3',
            assignee: 'Penny',
            title: 'Departed Completed Mop',
            status: 'completed',
            points: 35,
            isViewerActiveMember: false,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChoresView(
                user: user,
                bounties: departedBounties,
                memberHouseholdIds: const {},
                isLoading: false,
                onRefresh: () async {},
                onSelectBounty: (_) {},
                onCreateBounty: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Departed Open Dish'), findsNothing);
        expect(find.text('Departed Review Dish'), findsNothing);

        await tester.tap(find.text('Available'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Completed').last);
        await tester.pumpAndSettle();
        expect(find.text('Departed Completed Mop'), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileView(
                currentUser: user,
                myHouseholds: const [],
                memberHouseholdIds: const {},
                bounties: departedBounties,
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
        await tester.pump();

        expect(find.text('Departed Review Dish'), findsNothing);
        expect(find.text('Departed Open Dish'), findsNothing);
      },
    );
  });

  group('Request Redo modal redesign', () {
    testWidgets(
      'displays system-aligned AlertDialog, feedback input, Cancel and Request Redo CTA without icon badge',
      (tester) async {
        final service = _FakeRejectBountyService();
        final submittedBounty = Bounty(
          id: '42',
          creatorId: '1',
          creator: 'Leonard',
          assigneeId: '2',
          assignee: 'Sheldon',
          title: 'Empty trash cans',
          status: 'submitted',
          points: 15,
          submittedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BountyDetailScreen(
              bounty: submittedBounty,
              currentUser: const AppUser(
                id: 1,
                name: 'Leonard',
                email: 'leonard@example.com',
              ),
              service: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Request Redo'));
        await tester.pumpAndSettle();

        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(dialog.backgroundColor, Colors.white);
        expect(dialog.surfaceTintColor, Colors.transparent);
        expect(
          dialog.shape,
          isA<RoundedRectangleBorder>().having(
            (s) => s.borderRadius,
            'borderRadius',
            BorderRadius.circular(24),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byIcon(Icons.replay_rounded),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Optional note for the roommate...'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(OutlinedButton),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
          findsOneWidget,
        );

        // Cancel closes without invoking reject.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(service.rejectCalls, 0);

        // Re-open, enter feedback, and confirm Request Redo.
        await tester.tap(find.text('Request Redo'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Please tie the liner',
        );
        await tester.tap(find.text('Request Redo').last);
        await tester.pumpAndSettle();

        expect(service.rejectCalls, 1);
        expect(service.lastRejectedId, '42');
        expect(service.lastRejectFeedback, 'Please tie the liner');
      },
    );

    testWidgets(
      'ConfirmActionDialog and notification modals share unified AlertDialog styling',
      (tester) async {
        bool? confirmed;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    confirmed = await ConfirmActionDialog.show(
                      context,
                      title: 'Delete Chore',
                      message: 'Delete this chore permanently?',
                      cancelLabel: 'Keep',
                      confirmLabel: 'Delete',
                      confirmColor: AppModalDialog.dangerRed,
                    );
                  },
                  child: const Text('Open Confirm'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Confirm'));
        await tester.pumpAndSettle();

        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(dialog.backgroundColor, Colors.white);
        expect(dialog.surfaceTintColor, Colors.transparent);
        expect(dialog.elevation, 0);
        expect(
          dialog.shape,
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        );
        expect(find.text('Delete Chore'), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(confirmed, isTrue);
      },
    );
  });

  group('RedoRequestedDialog & HomeShell receiving-user redo modal', () {
    test('AppNotification extracts redoFeedback and redoChoreTitle accurately', () {
      final withColonNote = AppNotification(
        id: '77',
        eventName: 'Redo Requested',
        description:
            'Sheldon Cooper requested a redo on "Empty trash cans": Missed corners: check behind the bin',
        bountyTitle: 'Empty trash cans',
        eventType: 'redo',
        actorName: 'Sheldon Cooper',
        createdAt: DateTime.now(),
      );
      expect(withColonNote.redoChoreTitle, 'Empty trash cans');
      expect(
        withColonNote.redoFeedback,
        'Missed corners: check behind the bin',
      );

      final withoutNote = AppNotification(
        id: '78',
        eventName: 'Redo Requested',
        description: 'Sheldon Cooper requested a redo on "Sweep kitchen".',
        bountyTitle: 'Sweep kitchen',
        eventType: 'redo',
        actorName: 'Sheldon Cooper',
        createdAt: DateTime.now(),
      );
      expect(withoutNote.redoChoreTitle, 'Sweep kitchen');
      expect(withoutNote.redoFeedback, isNull);
    });

    testWidgets(
      'HomeShell displays RedoRequestedDialog with input message for receiving user and marks it read on close',
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
            id: 'derived-redo',
            householdId: '1',
            userId: '2',
            actorId: '1',
            eventName: 'Redo Requested',
            description: 'Sheldon Cooper requested a redo on "Old task": Ignore',
            eventType: 'redo',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: '77',
            householdId: '1',
            userId: '2',
            bountyId: '42',
            bountyTitle: 'Empty trash cans',
            actorId: '1',
            actorName: 'Sheldon Cooper',
            eventName: 'Redo Requested',
            description:
                'Sheldon Cooper requested a redo on "Empty trash cans": Please wipe the lid too',
            eventType: 'redo',
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

        expect(find.byType(RedoRequestedDialog), findsOneWidget);
        expect(find.text('Redo Requested'), findsOneWidget);
        expect(
          find.text('Sheldon Cooper requested a redo on "Empty trash cans".'),
          findsOneWidget,
        );
        expect(find.text('MESSAGE'), findsOneWidget);
        expect(find.text('Please wipe the lid too'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(RedoRequestedDialog), findsNothing);
        expect(fakeBounties.markedReadIds, ['77']);
      },
    );

    testWidgets('RedoRequestedDialog triggers onViewChore callback', (tester) async {
      var viewed = false;
      final redoNotif = AppNotification(
        id: '90',
        bountyId: '42',
        bountyTitle: 'Mop hallway',
        actorName: 'Penny',
        eventName: 'Redo Requested',
        description: 'Penny requested a redo on "Mop hallway": Rinse corners',
        eventType: 'redo',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RedoRequestedDialog.show(
                  context,
                  [redoNotif],
                  onViewChore: () => viewed = true,
                ),
                child: const Text('Open Redo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Redo'));
      await tester.pumpAndSettle();

      expect(find.text('Rinse corners'), findsOneWidget);
      await tester.tap(find.text('View Chore'));
      await tester.pumpAndSettle();

      expect(viewed, isTrue);
      expect(find.byType(RedoRequestedDialog), findsNothing);
    });
  });

  group('DashboardHeader unread count badge', () {
    testWidgets(
      'hides badge at 0, shows exact unread count, and caps at 99+',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(notificationCount: 0),
            ),
          ),
        );
        expect(find.text('0'), findsNothing);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(notificationCount: 7),
            ),
          ),
        );
        expect(find.text('7'), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(notificationCount: 120),
            ),
          ),
        );
        expect(find.text('99+'), findsOneWidget);
      },
    );
  });

  group('Dashboard Available Chores exclusion & household member notifications', () {
    testWidgets(
      'DashboardView Available Chores excludes user own posted chores and shows only other users chores',
      (tester) async {
        const currentUser = AppUser(
          id: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@example.com',
        );
        const household = Household(
          id: 10,
          name: 'Apt 4A',
          inviteCode: 'APT4A1',
        );

        const bounties = [
          Bounty(
            id: '1',
            householdId: '10',
            creatorId: '1',
            creator: 'Sheldon Cooper',
            title: 'My Own Posted Open Chore',
            status: 'open',
            points: 25,
          ),
          Bounty(
            id: '2',
            householdId: '10',
            creatorId: '',
            creator: 'sheldon cooper',
            title: 'My Own Name Matched Chore',
            status: 'open',
            points: 15,
          ),
          Bounty(
            id: '3',
            householdId: '10',
            creatorId: '2',
            creator: 'Leonard Hofstadter',
            title: 'Roommate Posted Available Chore',
            status: 'open',
            points: 30,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardView(
                user: currentUser,
                currentHousehold: household,
                myHouseholds: const [household],
                memberHouseholdIds: const {'10'},
                bounties: bounties,
                leaderboard: const [],
                isLoading: false,
                onRefresh: () async {},
                onSelectBounty: (_) {},
                onCreateBounty: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Roommate Posted Available Chore'), findsOneWidget);
        expect(find.text('My Own Posted Open Chore'), findsNothing);
        expect(find.text('My Own Name Matched Chore'), findsNothing);
      },
    );

    testWidgets(
      'NotificationsScreen renders member_joined and member_left cards with distinct icons',
      (tester) async {
        const user = AppUser(
          id: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@example.com',
        );
        final notifications = [
          AppNotification(
            id: '501',
            householdId: '10',
            userId: '1',
            actorId: '3',
            actorName: 'Howard Wolowitz',
            eventType: 'member_joined',
            eventName: 'Member Joined',
            description: 'Howard Wolowitz joined "Apt 4A".',
            category: 'Household',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: '502',
            householdId: '10',
            userId: '1',
            actorId: '4',
            actorName: 'Raj Koothrappali',
            eventType: 'member_left',
            eventName: 'Member Left',
            description: 'Raj Koothrappali left "Apt 4A".',
            category: 'Household',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        ];
        final fakeBounties = _FakeCelebrationBountyService(notifications);

        await tester.pumpWidget(
          MaterialApp(
            home: NotificationsScreen(
              user: user,
              bounties: fakeBounties,
              householdId: '10',
              initialNotifications: notifications,
              onSelectBounty: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Member Joined'), findsOneWidget);
        expect(find.text('Howard Wolowitz joined "Apt 4A".'), findsOneWidget);
        expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);

        expect(find.text('Member Left'), findsOneWidget);
        expect(find.text('Raj Koothrappali left "Apt 4A".'), findsOneWidget);
        expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);

        // Tapping a household membership notification marks it read cleanly.
        await tester.tap(find.text('Member Joined'));
        await tester.pumpAndSettle();
        expect(fakeBounties.markedReadIds, ['501']);
      },
    );
  });

  group('HouseholdPage transfer ownership and leave household', () {
    testWidgets(
      'owner can transfer ownership to another member via picker or row action, and users can leave from HouseholdView',
      (tester) async {
        const ownerUser = AppUser(
          id: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@example.com',
        );
        const regularUser = AppUser(
          id: 2,
          name: 'Leonard Hofstadter',
          email: 'leonard@example.com',
        );
        const householdAsOwner = Household(
          id: 10,
          name: 'Apt 4A',
          inviteCode: 'APT4A1',
          createdBy: 1,
          role: 'owner',
          membersCount: 2,
        );
        const householdAsMember = Household(
          id: 10,
          name: 'Apt 4A',
          inviteCode: 'APT4A1',
          createdBy: 1,
          role: 'member',
          membersCount: 2,
        );
        const members = [
          HouseholdMember(
            userId: 1,
            name: 'Sheldon Cooper',
            email: 'sheldon@example.com',
            role: 'owner',
          ),
          HouseholdMember(
            userId: 2,
            name: 'Leonard Hofstadter',
            email: 'leonard@example.com',
            role: 'member',
          ),
        ];

        HouseholdMember? transferredTo;
        Household? leftHousehold;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HouseholdView(
                currentUser: ownerUser,
                currentHousehold: householdAsOwner,
                members: members,
                isLoading: false,
                onRefresh: () async {},
                onTransferOwnership: (_, member) async =>
                    transferredTo = member,
                onLeaveHousehold: (h) async => leftHousehold = h,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Transfer Ownership'), findsNothing);
        expect(find.byTooltip('Transfer ownership'), findsOneWidget);
        expect(find.text('Leave Household'), findsOneWidget);

        // Owner taps inline Transfer ownership button and confirms.
        await tester.tap(find.byTooltip('Transfer ownership'));
        await tester.pumpAndSettle();

        expect(find.text('Make Leonard Hofstadter owner?'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byIcon(Icons.swap_horiz_rounded),
          ),
          findsNothing,
        );
        await tester.tap(find.text('Transfer'));
        await tester.pumpAndSettle();

        expect(transferredTo?.userId, 2);

        // User taps Leave Household from Household page.
        await tester.ensureVisible(find.text('Leave Household'));
        await tester.tap(find.text('Leave Household'));
        await tester.pumpAndSettle();
        expect(leftHousehold?.id, 10);

        // Non-owner member sees Leave Household but not Transfer Ownership.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HouseholdView(
                currentUser: regularUser,
                currentHousehold: householdAsMember,
                members: members,
                isLoading: false,
                onRefresh: () async {},
                onTransferOwnership: (_, _) async {},
                onLeaveHousehold: (_) async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Transfer Ownership'), findsNothing);
        expect(find.byTooltip('Transfer ownership'), findsNothing);
        expect(find.text('Leave Household'), findsOneWidget);
      },
    );
  });

  group('Departed housemate earned tokens', () {
    testWidgets(
      'UserDetailScreen displays earned tokens of a housemate who left the household',
      (tester) async {
        const activeUser = AppUser(
          id: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@example.com',
        );
        const household = Household(
          id: 10,
          name: 'Apt 4A',
          inviteCode: 'APT4A1',
          createdBy: 1,
          role: 'owner',
          membersCount: 1,
        );

        // Penny (id: 3) and Howard (id: 4) already left the household.
        const bounties = [
          Bounty(
            id: '101',
            householdId: '10',
            creatorId: '1',
            creator: 'Sheldon Cooper',
            assigneeId: '3',
            assignee: 'Penny Teller',
            title: 'Wipe kitchen counters',
            status: 'completed',
            points: 35,
          ),
          Bounty(
            id: '102',
            householdId: '10',
            creatorId: '4',
            creator: 'Howard Wolowitz',
            assigneeId: '3',
            assignee: 'Penny Teller',
            title: 'Restock pantry',
            status: 'completed',
            points: 0,
            rewardValue: 45.0,
            isCreatorActiveMember: false,
          ),
          Bounty(
            id: '103',
            householdId: '10',
            creatorId: '1',
            creator: 'Sheldon Cooper',
            assigneeId: '3',
            assignee: 'Penny Teller',
            title: 'Take out trash',
            status: 'claimed',
            points: 20,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: UserDetailScreen(
              currentUser: activeUser,
              userId: 3,
              name: 'Penny Teller',
              totalTokens: 0,
              completedCount: 0,
              household: household,
              bounties: bounties,
              memberHouseholdIds: const {'10'},
              activeMemberIds: const {'1'},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rank is empty because departed member is not on the leaderboard,
        // while Points and Completed reflect Penny's completed chores (35 + 45 = 80).
        expect(find.text('—'), findsOneWidget);
        expect(find.text('80'), findsOneWidget);
        expect(find.text('2'), findsWidgets);
        expect(find.text('Wipe kitchen counters'), findsOneWidget);
        expect(find.text('Restock pantry'), findsOneWidget);
      },
    );
  });

  group('Taken chore past due date', () {
    test('Bounty.canSubmit is false when taken chore is beyond due date', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      final future = DateTime.now().add(const Duration(hours: 2));

      final pastDueTaken = Bounty(
        id: '201',
        creatorId: '1',
        assigneeId: '2',
        title: 'Mop hallway',
        status: 'claimed',
        dueAt: past,
      );
      final futureTaken = Bounty(
        id: '202',
        creatorId: '1',
        assigneeId: '2',
        title: 'Mop hallway',
        status: 'claimed',
        dueAt: future,
      );
      const undatedTaken = Bounty(
        id: '203',
        creatorId: '1',
        assigneeId: '2',
        title: 'Mop hallway',
        status: 'claimed',
      );

      expect(pastDueTaken.isTaken, isTrue);
      expect(pastDueTaken.isDeadlinePassed, isTrue);
      expect(pastDueTaken.canSubmit, isFalse);
      expect(futureTaken.canSubmit, isTrue);
      expect(undatedTaken.canSubmit, isTrue);
    });

    testWidgets(
      'BountyDetailScreen hides proof input and Submit button when taken chore is past due',
      (tester) async {
        const assignee = AppUser(
          id: 2,
          name: 'Amy Farrah Fowler',
          email: 'amy@example.com',
        );
        final pastDueClaimed = Bounty(
          id: '204',
          householdId: '2',
          creatorId: '1',
          creator: 'Sheldon Cooper',
          assigneeId: '2',
          assignee: 'Amy Farrah Fowler',
          title: 'Take out recycling',
          status: 'claimed',
          points: 20,
          dueAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );

        final fakeService = _FakeSubmitBountyService();

        await tester.pumpWidget(
          MaterialApp(
            home: BountyDetailScreen(
              bounty: pastDueClaimed,
              currentUser: assignee,
              service: fakeService,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Submit for Review'), findsNothing);
        expect(find.text('Open Camera'), findsNothing);
        expect(find.text('Submission Note / Proof'), findsNothing);
        expect(find.text('Past Due'), findsOneWidget);
        expect(find.text('Abandon Quest'), findsOneWidget);
        expect(fakeService.submitCalls, 0);
      },
    );
  });

  group('Change password and invite code regeneration', () {
    Widget changePasswordHost(
      _FakeChangePasswordAuthService auth,
      void Function(bool?) onResult,
    ) {
      return MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordScreen(auth: auth),
                    ),
                  );
                  onResult(result);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('ChangePasswordScreen validates input before calling the API',
        (tester) async {
      final auth = _FakeChangePasswordAuthService();
      await tester.pumpWidget(changePasswordHost(auth, (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Current password is required.'), findsOneWidget);
      expect(find.text('New password is required.'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'old-password-1');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'other');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);

      await tester.enterText(fields.at(1), 'old-password-1');
      await tester.enterText(fields.at(2), 'old-password-1');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(
        find.text('Use a password different from the current one.'),
        findsOneWidget,
      );
      expect(auth.calls, 0);
    });

    testWidgets('ChangePasswordScreen submits values and closes on success',
        (tester) async {
      final auth = _FakeChangePasswordAuthService();
      bool? result;
      await tester.pumpWidget(changePasswordHost(auth, (r) => result = r));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'old-password-1');
      await tester.enterText(fields.at(1), 'new-password-1');
      await tester.enterText(fields.at(2), 'new-password-1');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      expect(auth.lastCurrent, 'old-password-1');
      expect(auth.lastNew, 'new-password-1');
      expect(auth.lastConfirmation, 'new-password-1');
      expect(result, isTrue);
      expect(find.byType(ChangePasswordScreen), findsNothing);
    });

    testWidgets('ChangePasswordScreen shows the API error and stays open',
        (tester) async {
      final request = RequestOptions(path: '/user/password');
      final auth = _FakeChangePasswordAuthService(
        errorToThrow: DioException(
          requestOptions: request,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 422,
            data: {
              'errors': {
                'current_password': ['The current password is incorrect.'],
              },
            },
          ),
        ),
      );
      await tester.pumpWidget(changePasswordHost(auth, (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'wrong-password');
      await tester.enterText(fields.at(1), 'new-password-1');
      await tester.enterText(fields.at(2), 'new-password-1');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('The current password is incorrect.'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('HouseholdView lets only the owner regenerate the invite code',
        (tester) async {
      const owner = AppUser(id: 1, name: 'Sheldon Cooper', email: 's@test.com');
      const member = AppUser(id: 2, name: 'Leonard', email: 'l@test.com');
      const asOwner = Household(
        id: 10,
        name: 'Apt 4A',
        inviteCode: 'OLDCODE1',
        createdBy: 1,
        role: 'owner',
        membersCount: 2,
      );
      const asMember = Household(
        id: 10,
        name: 'Apt 4A',
        inviteCode: 'OLDCODE1',
        createdBy: 1,
        role: 'member',
        membersCount: 2,
      );
      const members = [
        HouseholdMember(
          userId: 1,
          name: 'Sheldon Cooper',
          email: 's@test.com',
          role: 'owner',
        ),
        HouseholdMember(
          userId: 2,
          name: 'Leonard',
          email: 'l@test.com',
          role: 'member',
        ),
      ];

      Household? regenerated;
      Widget build(AppUser user, Household household) => MaterialApp(
            home: Scaffold(
              body: HouseholdView(
                currentUser: user,
                currentHousehold: household,
                members: members,
                isLoading: false,
                onRefresh: () async {},
                onRegenerateInviteCode: (h) async => regenerated = h,
              ),
            ),
          );

      await tester.pumpWidget(build(owner, asOwner));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Generate new invite code'), findsOneWidget);

      // Cancel keeps the current code.
      await tester.tap(find.byTooltip('Generate new invite code'));
      await tester.pumpAndSettle();
      expect(find.text('Generate a new invite code?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(regenerated, isNull);

      // Confirm calls the callback.
      await tester.tap(find.byTooltip('Generate new invite code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();
      expect(regenerated?.id, 10);

      // Members do not see the control.
      await tester.pumpWidget(build(member, asMember));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Generate new invite code'), findsNothing);
    });
  });
}

class _FakeChangePasswordAuthService extends AuthService {
  _FakeChangePasswordAuthService({this.errorToThrow})
      : super(ApiClient(_MemoryTokenStorage()), _MemoryTokenStorage());

  final DioException? errorToThrow;
  int calls = 0;
  String? lastCurrent;
  String? lastNew;
  String? lastConfirmation;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    calls++;
    lastCurrent = currentPassword;
    lastNew = newPassword;
    lastConfirmation = confirmation;
    if (errorToThrow != null) throw errorToThrow!;
  }
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

class _FakeSubmitBountyService extends BountyService {
  _FakeSubmitBountyService() : super(ApiClient(_MemoryTokenStorage()));

  int submitCalls = 0;
  String? lastProof;
  List<String> lastImagePaths = const [];

  @override
  Future<void> submit(
    String id, {
    String? proof,
    List<String> imagePaths = const [],
  }) async {
    submitCalls++;
    lastProof = proof;
    lastImagePaths = List<String>.from(imagePaths);
  }
}

class _FakeRejectBountyService extends BountyService {
  _FakeRejectBountyService() : super(ApiClient(_MemoryTokenStorage()));

  int rejectCalls = 0;
  String? lastRejectedId;
  String? lastRejectFeedback;

  @override
  Future<Bounty> reject(String id, {String? feedback}) async {
    rejectCalls++;
    lastRejectedId = id;
    lastRejectFeedback = feedback;
    return Bounty(
      id: id,
      creatorId: '1',
      creator: 'Leonard',
      assigneeId: '2',
      assignee: 'Sheldon',
      title: 'Empty trash cans',
      status: 'claimed',
      points: 15,
    );
  }
}

class _StubHttpAdapter implements HttpClientAdapter {
  _StubHttpAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);
}
