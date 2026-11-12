import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chore_bounty_application/main.dart';
import 'package:chore_bounty_application/core/api_client.dart';
import 'package:chore_bounty_application/core/token_storage.dart';
import 'package:chore_bounty_application/models/app_user.dart';
import 'package:chore_bounty_application/models/bounty.dart';
import 'package:chore_bounty_application/models/household.dart';
import 'package:chore_bounty_application/models/household_member.dart';
import 'package:chore_bounty_application/models/leaderboard_entry.dart';
import 'package:chore_bounty_application/screens/home_shell.dart';
import 'package:chore_bounty_application/screens/household_prompt_screen.dart';
import 'package:chore_bounty_application/services/auth_service.dart';
import 'package:chore_bounty_application/services/bounty_service.dart';
import 'package:chore_bounty_application/services/household_service.dart';
import 'package:chore_bounty_application/widgets/avatar/user_avatar_widget.dart';
import 'package:chore_bounty_application/widgets/ui.dart';
import 'package:chore_bounty_application/widgets/bounty_form/bounty_category_icons.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_bounty_card.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_header.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_illustrations.dart';
import 'package:chore_bounty_application/widgets/dashboard/dashboard_summary_card.dart';

void main() {
  testWidgets('ChoreBounty app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ChoreBountyApp());

    // Allow the first frame and immediate scheduled updates to render.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ChoreBountyApp), findsOneWidget);
  });

  testWidgets('CategoryIconWidget, BountyCoinWidget and TrashBinWidget render correctly',
      (WidgetTester tester) async {
    const testCategories = [
      'Cleaning',
      'Laundry',
      'Kitchen',
      'Groceries',
      'Maintenance',
      'Other',
      'Dishes',
      'Trash',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const BountyCoinWidget(size: 32),
                const TrashBinWidget(size: 32),
                ...testCategories.map(
                  (cat) => CategoryIconWidget(category: cat, size: 34),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(BountyCoinWidget), findsOneWidget);
    expect(find.byType(TrashBinWidget), findsOneWidget);
    expect(find.byType(CategoryIconWidget), findsNWidgets(testCategories.length));
  });

  testWidgets('DashboardHeader renders hamburger button and bell without name text, and hides red dot when notificationCount is 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardHeader(
            userName: 'Leonard',
            householdName: 'Apartment 4A',
            notificationCount: 0,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify name and greeting are removed from header
    expect(find.text('Leonard'), findsNothing);
    expect(find.text('Hello,'), findsNothing);
    expect(find.text('Apartment 4A'), findsNothing);

    // Verify hamburger and bell icons are present
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Verify red dot is NOT rendered when notificationCount is 0
    final redDotFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFEF4444);
      }
      return false;
    });
    expect(redDotFinder, findsNothing);
  });

  testWidgets('DashboardSummaryCard displays points, task count and household dropdown',
      (WidgetTester tester) async {
    bool householdTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryCard(
            points: 150,
            tasksOngoing: 2,
            householdName: 'Apartment 4A',
            onHouseholdTap: () {
              householdTapped = true;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify points, tasks ongoing and household dropdown are rendered
    expect(find.text('150'), findsOneWidget);
    expect(find.text('Points'), findsOneWidget);
    expect(find.text('2 tasks ongoing'), findsOneWidget);
    expect(find.text('Apartment 4A'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    // Tap household dropdown
    await tester.tap(find.text('Apartment 4A'));
    await tester.pump();
    expect(householdTapped, isTrue);
  });

  testWidgets('DashboardHeader shows red dot when notificationCount is greater than 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardHeader(
            userName: 'Leonard',
            householdName: 'Apartment 4A',
            notificationCount: 1,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify red dot IS rendered when notificationCount is 1
    final redDotFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFEF4444);
      }
      return false;
    });
    expect(redDotFinder, findsOneWidget);
  });

  testWidgets('DashboardBountyCard displays formatted time left with pluralization, zero omission and seconds fallback',
      (WidgetTester tester) async {
    final now = DateTime.now();

    // Bounty with 1 day, 2 hours, 15 minutes (non-zero days, hours, minutes)
    final myBounty = Bounty(
      id: '1',
      title: 'Buy dinner',
      creatorId: '42',
      creator: 'Sheldon Cooper',
      points: 25,
      category: 'Groceries',
      dueAt: now.add(const Duration(days: 1, hours: 2, minutes: 15, seconds: 5)),
      createdAt: now.subtract(const Duration(minutes: 10)),
    );

    // Bounty with 0 days, 3 hours, 20 minutes (zero days omitted)
    final othersBounty = Bounty(
      id: '2',
      title: 'Cook breakfast',
      creatorId: '99',
      creator: 'Leonard Hofstadter',
      points: 50,
      category: 'Kitchen',
      dueAt: now.add(const Duration(hours: 3, minutes: 20, seconds: 5)),
      createdAt: now.subtract(const Duration(minutes: 20)),
    );

    // Bounty with 0 minutes (shows seconds)
    final secondsBounty = Bounty(
      id: '3',
      title: 'Quick check',
      creatorId: '99',
      creator: 'Leonard Hofstadter',
      points: 10,
      category: 'Cleaning',
      dueAt: now.add(const Duration(seconds: 45)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DashboardBountyCard(
                  bounty: myBounty,
                  currentUserId: '42',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
                DashboardBountyCard(
                  bounty: othersBounty,
                  currentUserId: '42',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
                DashboardBountyCard(
                  bounty: secondsBounty,
                  currentUserId: '42',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify creator name replacement for logged user's posted chore
    expect(find.textContaining('Posted by you'), findsOneWidget);
    expect(find.textContaining('Posted by Leonard'), findsNWidgets(2));

    // Verify myBounty (1 Day, 2 Hours, 15 Minutes) - "Day" without s, "Hours" and "Minutes" with s
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return RegExp(r'1 Day, 2 Hours, (14|15) Minutes').hasMatch(widget.data!);
        }
        return false;
      }),
      findsOneWidget,
    );

    // Verify othersBounty (3 Hours, 20 Minutes) - 0 days is omitted!
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return RegExp(r'3 Hours, (19|20) Minutes').hasMatch(widget.data!);
        }
        return false;
      }),
      findsOneWidget,
    );

    // Verify secondsBounty - minute is 0, so seconds is shown
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is Text && widget.data != null) {
          return RegExp(r'\d+ Seconds').hasMatch(widget.data!);
        }
        return false;
      }),
      findsOneWidget,
    );
  });

  testWidgets('BountyDetailScreen dedicated chore page renders wireframe layout with details and claim button',
      (WidgetTester tester) async {
    final bounty = Bounty(
      id: '10',
      householdId: '1',
      creatorId: '2',
      creator: 'Sheldon',
      title: 'Do the laundry',
      description: 'Wash sheets and clothes in warm water.',
      difficulty: 'medium',
      category: 'Laundry',
      points: 50,
      rewardValue: 50.0,
      reward: '50 Tokens',
      status: 'open',
      dueAt: DateTime.now().add(const Duration(days: 3, hours: 9)),
    );

    const currentUser = AppUser(
      id: 1,
      name: 'Leonard',
      email: 'leonard@example.com',
    );

    final service = BountyService(ApiClient(TokenStorage()));

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          bounty: bounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );

    await tester.pump();

    // Verify title 'Bounty Details' on AppBar
    expect(find.text('Bounty Details'), findsOneWidget);

    // Verify chore title, category icon and poster name
    expect(find.text('Do the laundry'), findsOneWidget);
    expect(find.text('Sheldon'), findsOneWidget);
    expect(find.text('50 Tokens'), findsOneWidget);
    expect(find.byType(CategoryIconWidget), findsOneWidget);

    // Verify description box
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Wash sheets and clothes in warm water.'), findsOneWidget);

    // Verify bottom action button: 'Claim This Bounty'
    expect(find.text('Claim This Bounty'), findsOneWidget);
  });

  testWidgets('BountyDetailScreen renders schedule due date with calendar icon and category with tag icon',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final todayEightPm = DateTime(now.year, now.month, now.day, 20, 0);

    final bounty = Bounty(
      id: '30',
      householdId: '1',
      creatorId: '2',
      creator: 'Sheldon Cooper',
      title: 'Clean the kitchen',
      description: 'Wipe all counters and wash dishes.',
      difficulty: 'medium',
      category: 'Cleaning',
      points: 50,
      rewardValue: 50.0,
      reward: '50 Tokens',
      status: 'claimed',
      assigneeId: '1',
      dueAt: todayEightPm,
    );

    const currentUser = AppUser(
      id: 1,
      name: 'Leonard Hofstadter',
      email: 'leonard@gmail.com',
    );

    final service = BountyService(ApiClient(TokenStorage()));

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          bounty: bounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );

    await tester.pump();

    // Verify Submission Note / Proof is rendered for claimed assignee
    expect(find.text('Submission Note / Proof'), findsOneWidget);
    expect(find.text('Submit for Review'), findsOneWidget);
    final descriptionHeader = tester.widget<Text>(find.text('Description'));
    final descBodyText = tester.widget<Text>(find.text('Wipe all counters and wash dishes.'));

    // Scroll to reveal the schedule details card in the yellow box position
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify Details card header, calendar icon and schedule text 'Due today, 8:00 PM'
    expect(find.text('Details'), findsOneWidget);
    final detailsHeader = tester.widget<Text>(find.text('Details'));
    expect(detailsHeader.style?.fontSize, descriptionHeader.style?.fontSize);

    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    expect(find.text('Due today, 8:00 PM'), findsOneWidget);
    final dueText = tester.widget<Text>(find.text('Due today, 8:00 PM'));
    expect(dueText.style?.fontSize, descBodyText.style?.fontSize);

    // Verify tag icon and category 'Cleaning'
    expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    final categoryText = tester.widget<Text>(find.text('Cleaning'));
    expect(categoryText.style?.fontSize, descBodyText.style?.fontSize);
  });

  testWidgets('BountyDetailScreen removes top due date, resolves category name instead of difficulty, and sets button container background to transparent',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final todayEightPm = DateTime(now.year, now.month, now.day, 20, 0);

    final bounty = Bounty(
      id: '40',
      householdId: '1',
      creatorId: '2',
      creator: 'Sheldon Cooper',
      title: 'Do the laundry',
      description: 'Wash all sheets and clothes.',
      difficulty: 'medium',
      category: 'medium',
      points: 50,
      rewardValue: 50.0,
      reward: '50 Tokens',
      status: 'claimed',
      assigneeId: '1',
      dueAt: todayEightPm,
    );

    const currentUser = AppUser(
      id: 1,
      name: 'Leonard Hofstadter',
      email: 'leonard@gmail.com',
    );

    final service = BountyService(ApiClient(TokenStorage()));

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          bounty: bounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );

    await tester.pump();

    // 1. Verify top card does not contain access_time_rounded clock icon or countdown due text
    expect(find.byIcon(Icons.access_time_rounded), findsNothing);
    expect(find.textContaining('Due in'), findsNothing);

    // 2. Scroll to reveal details card
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // 3. Verify category displays 'Laundry' instead of 'Medium'
    expect(find.text('Laundry'), findsOneWidget);
    expect(find.text('Medium'), findsNothing);

    // 4. Verify action button is present and functional
    expect(find.text('Submit for Review'), findsOneWidget);
  });

  testWidgets('BountyDetailScreen renders full name instead of "you" and renders Edit, Cancel, and Delete buttons in one row for creator',
      (WidgetTester tester) async {
    final bounty = Bounty(
      id: '20',
      householdId: '1',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      title: 'Buy dinner',
      description: 'Buy a dinner for tonight.',
      difficulty: 'easy',
      category: 'Groceries',
      points: 50,
      rewardValue: 50.0,
      reward: '50 Tokens',
      status: 'open',
      dueAt: DateTime.now().add(const Duration(hours: 6, minutes: 2)),
    );

    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
    );

    final service = BountyService(ApiClient(TokenStorage()));

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          bounty: bounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );

    await tester.pump();

    // Verify creator's full name is rendered and not "you"
    expect(find.text('Sheldon Cooper'), findsOneWidget);
    expect(find.text('you'), findsNothing);

    // Verify Edit, Cancel, and Delete buttons are present in a single row
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    final editTopY = tester.getTopLeft(find.text('Edit')).dy;
    final cancelTopY = tester.getTopLeft(find.text('Cancel')).dy;
    final deleteTopY = tester.getTopLeft(find.text('Delete')).dy;
    expect(cancelTopY, editTopY);
    expect(deleteTopY, editTopY);

    // Tap 'Edit' and verify navigation to populated CreateBounty form
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateBounty), findsOneWidget);
    expect(find.text('Buy dinner'), findsOneWidget);
    expect(find.text('Buy a dinner for tonight.'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('Drawer displays user name and email address in bottom section',
      (WidgetTester tester) async {
    const testUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
      avatar: 'avatar_1',
    );
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  const Expanded(
                    child: SizedBox(),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        UserAvatarWidget(
                          avatarId: testUser.avatar,
                          userName: testUser.name,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testUser.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                testUser.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Center(
            child: ElevatedButton(
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Sheldon Cooper'), findsOneWidget);
    expect(find.text('sheldon@gmail.com'), findsOneWidget);
  });

  testWidgets('BountyDetailScreen displays Available, Taken, Completed, and Cancelled status badges',
      (WidgetTester tester) async {
    final service = BountyService(ApiClient(TokenStorage()));
    const currentUser = AppUser(id: 1, name: 'Leonard', email: 'leonard@gmail.com');

    // 1. Open bounty -> Available
    final openBounty = Bounty(
      id: '50',
      householdId: '1',
      creatorId: '2',
      title: 'Buy dinner',
      status: 'open',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('open_bounty'),
          bounty: openBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Available'), findsOneWidget);

    // 2. Claimed bounty -> Taken
    final claimedBounty = Bounty(
      id: '51',
      householdId: '1',
      creatorId: '2',
      assigneeId: '1',
      title: 'Buy dinner',
      status: 'claimed',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('claimed_bounty'),
          bounty: claimedBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Taken'), findsOneWidget);

    // 3. Completed bounty -> Completed
    final completedBounty = Bounty(
      id: '52',
      householdId: '1',
      creatorId: '2',
      assigneeId: '1',
      title: 'Buy dinner',
      status: 'completed',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('completed_bounty'),
          bounty: completedBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Completed'), findsWidgets);

    // 4. Cancelled bounty -> Cancelled
    final cancelledBounty = Bounty(
      id: '53',
      householdId: '1',
      creatorId: '2',
      title: 'Buy dinner',
      status: 'cancelled',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('cancelled_bounty'),
          bounty: cancelledBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancelled'), findsNWidgets(2));
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('BountyDetailScreen renders Claimed by / Completed by card with proof below schedule card and removes old Proof Submitted box',
      (WidgetTester tester) async {
    final service = BountyService(ApiClient(TokenStorage()));
    const currentUser = AppUser(
      id: 1,
      name: 'France',
      email: 'france@gmail.com',
      avatar: 'guy_1',
    );
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1, minutes: 5));

    // 1. Open bounty should NOT display Claimed by or Completed by
    final openBounty = Bounty(
      id: '60',
      householdId: '1',
      creatorId: '2',
      creator: 'Sheldon Cooper',
      title: 'Clean the room',
      status: 'open',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('open_no_claimant'),
          bounty: openBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Claimed by'), findsNothing);
    expect(find.text('Completed by'), findsNothing);

    // 2. Claimed bounty shows 'Claimed by', assignee with '(You)', and relative time
    final claimedBounty = Bounty(
      id: '61',
      householdId: '1',
      creatorId: '2',
      creator: 'Sheldon Cooper',
      assigneeId: '1',
      assignee: 'France',
      title: 'Clean the room',
      category: 'Cleaning',
      status: 'claimed',
      claimedAt: oneHourAgo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('claimed_with_claimant'),
          bounty: claimedBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Claimed by'), findsOneWidget);
    expect(find.text('France (You)'), findsOneWidget);
    expect(find.text('1h ago'), findsOneWidget);

    // 3. Completed bounty shows 'Completed by', completer, time ago, and proof inside card below schedule
    final completedBounty = Bounty(
      id: '62',
      householdId: '1',
      creatorId: '2',
      creator: 'Sheldon Cooper',
      assigneeId: '1',
      assignee: 'France',
      title: 'Clean the room',
      description: 'Clean the room',
      category: 'Cleaning',
      status: 'completed',
      submissionProof: 'Chore finished',
      claimedAt: oneHourAgo,
      completedAt: oneHourAgo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('completed_with_proof'),
          bounty: completedBounty,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Standalone colon-suffixed 'Proof Submitted:' card is removed
    expect(find.text('Proof Submitted:'), findsNothing);

    // Claimed/Completed + Proof card appears below Schedule/Category
    expect(find.text('Completed by'), findsOneWidget);
    expect(find.text('France (You)'), findsOneWidget);
    expect(find.text('1h ago'), findsOneWidget);
    expect(find.text('Proof Submitted'), findsOneWidget);
    expect(find.text('Chore finished'), findsOneWidget);

    final categoryTopLeft = tester.getTopLeft(find.text('Cleaning'));
    final completedByTopLeft = tester.getTopLeft(find.text('Completed by'));
    final proofTopLeft = tester.getTopLeft(find.text('Chore finished'));
    expect(completedByTopLeft.dy, greaterThan(categoryTopLeft.dy));
    expect(proofTopLeft.dy, greaterThan(completedByTopLeft.dy));

    // 4. Submitted bounty viewed by creator/non-assignee shows 'Claimed by' without '(You)' and includes proof
    final submittedForReview = Bounty(
      id: '63',
      householdId: '1',
      creatorId: '1',
      creator: 'France',
      assigneeId: '2',
      assignee: 'Sheldon Cooper',
      assigneeAvatar: 'guy_2',
      title: 'Clean the room',
      category: 'Cleaning',
      status: 'submitted',
      submissionProof: 'Vacuumed and mopped the floor',
      claimedAt: oneHourAgo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('submitted_other_assignee'),
          bounty: submittedForReview,
          currentUser: currentUser,
          service: service,
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Proof Submitted:'), findsNothing);
    expect(find.text('Claimed by'), findsOneWidget);
    expect(find.text('Sheldon Cooper'), findsOneWidget);
    expect(find.text('Sheldon Cooper (You)'), findsNothing);
    expect(find.text('1h ago'), findsOneWidget);
    expect(find.text('Proof Submitted'), findsOneWidget);
    expect(find.text('Vacuumed and mopped the floor'), findsOneWidget);
  });

  testWidgets('BountyDetailScreen uses accurate creator and assignee profile pictures via Bounty fields, memberAvatars fallback, and refreshOnOpen',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );

    // 1. Uses memberAvatars fallback when stale Bounty lacks creatorAvatar / assigneeAvatar
    final staleBounty = Bounty(
      id: '3',
      householdId: '2',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      assigneeId: '2',
      assignee: 'Leonard Hofstadter',
      title: 'Do the laundry',
      status: 'claimed',
      claimedAt: DateTime.now().subtract(const Duration(hours: 4)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('stale_with_map'),
          bounty: staleBounty,
          currentUser: currentUser,
          service: BountyService(ApiClient(TokenStorage())),
          memberAvatars: const {'1': 'guy_1', '2': 'guy_2'},
        ),
      ),
    );
    await tester.pump();

    final avatarsFromMap =
        tester.widgetList<UserAvatarWidget>(find.byType(UserAvatarWidget)).toList();
    expect(avatarsFromMap.length, 2);
    expect(avatarsFromMap[0].avatarId, 'guy_1');
    expect(avatarsFromMap[1].avatarId, 'guy_2');

    // 2. Refresh on open updates avatars when Bounties are refreshed via BountyService.show
    final freshBounty = Bounty(
      id: '3',
      householdId: '2',
      creatorId: '2',
      creator: 'Leonard Hofstadter',
      creatorAvatar: 'guy_2',
      assigneeId: '3',
      assignee: 'Penny',
      assigneeAvatar: 'gal_3',
      title: 'Do the laundry',
      status: 'claimed',
      claimedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final initialOtherBounty = Bounty(
      id: '3',
      householdId: '2',
      creatorId: '2',
      creator: 'Leonard Hofstadter',
      assigneeId: '3',
      assignee: 'Penny',
      title: 'Do the laundry',
      status: 'claimed',
      claimedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final fakeService = _FakeShowBountyService(freshBounty);

    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('refresh_on_open'),
          bounty: initialOtherBounty,
          currentUser: currentUser,
          service: fakeService,
          refreshOnOpen: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatarsAfterRefresh =
        tester.widgetList<UserAvatarWidget>(find.byType(UserAvatarWidget)).toList();
    expect(avatarsAfterRefresh.length, 2);
    expect(avatarsAfterRefresh[0].avatarId, 'guy_2');
    expect(avatarsAfterRefresh[1].avatarId, 'gal_3');
  });

  testWidgets('ChoresView displays Chores title, excludes user-posted chores from Available/In Progress/Completed, and provides a Status dropdown in Posted by Me',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      role: 'owner',
    );

    final bounties = [
      Bounty(
        id: '1',
        householdId: '2',
        creatorId: '2',
        creator: 'Leonard Hofstadter',
        title: 'Buy milk',
        category: 'Groceries',
        points: 20,
        status: 'open',
      ),
      Bounty(
        id: '2',
        householdId: '2',
        creatorId: '2',
        creator: 'Leonard Hofstadter',
        assigneeId: '1',
        assignee: 'Sheldon Cooper',
        title: 'Sweep hallway',
        category: 'Cleaning',
        points: 30,
        status: 'claimed',
      ),
      Bounty(
        id: '3',
        householdId: '2',
        creatorId: '2',
        creator: 'Leonard Hofstadter',
        assigneeId: '1',
        assignee: 'Sheldon Cooper',
        title: 'Cook breakfast',
        category: 'Kitchen',
        points: 50,
        status: 'completed',
      ),
      Bounty(
        id: '4',
        householdId: '2',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        title: 'Water plants',
        category: 'Other',
        points: 15,
        status: 'open',
      ),
      Bounty(
        id: '5',
        householdId: '2',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        assigneeId: '2',
        assignee: 'Leonard Hofstadter',
        title: 'Do the laundry',
        category: 'Laundry',
        points: 50,
        status: 'claimed',
      ),
      Bounty(
        id: '6',
        householdId: '2',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        assigneeId: '2',
        assignee: 'Leonard Hofstadter',
        title: 'Clean the room',
        category: 'Cleaning',
        points: 50,
        status: 'completed',
      ),
      Bounty(
        id: '7',
        householdId: '2',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        title: 'Buy dinner',
        category: 'Groceries',
        points: 25,
        status: 'cancelled',
      ),
    ];

    Bounty? tappedBounty;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChoresView(
            user: currentUser,
            currentHousehold: household,
            bounties: bounties,
            isLoading: false,
            onRefresh: () async {},
            onSelectBounty: (b) => tappedBounty = b,
            onCreateBounty: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Renamed to Bounties (no My Tasks title) and reuses DashboardBountyCard
    expect(find.text('Bounties'), findsOneWidget);
    expect(find.textContaining('My Tasks'), findsNothing);
    expect(find.byType(DashboardBountyCard), findsOneWidget);

    // 1. Default 'Available' filter -> open chores posted by OTHER users only ('Buy milk', not 'Water plants')
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Water plants'), findsNothing);
    expect(find.text('Sweep hallway'), findsNothing);
    expect(find.text('Status'), findsNothing);

    // 2. 'In Progress' filter -> active chores posted by OTHER users claimed by currentUser ('Sweep hallway')
    await tester.tap(find.text('In Progress'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('Sweep hallway'), findsOneWidget);
    expect(find.text('Do the laundry'), findsNothing);

    // 3. 'Completed' filter -> completed chores posted by OTHER users only ('Cook breakfast', not 'Clean the room')
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('Cook breakfast'), findsOneWidget);
    expect(find.text('Clean the room'), findsNothing);

    // 4. 'Posted by Me' filter -> creatorId == '1' + shows secondary Status dropdown filter
    await tester.ensureVisible(find.text('Posted by Me'));
    await tester.tap(find.text('Posted by Me'));
    await tester.pumpAndSettle();

    expect(find.text('Status'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.byType(DashboardBountyCard), findsNWidgets(4));

    // Dropdown -> 'Available'
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Available').last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('Water plants'), findsOneWidget);

    // Dropdown -> 'Taken'
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taken').last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('Do the laundry'), findsOneWidget);

    // Dropdown -> 'Completed'
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('Clean the room'), findsOneWidget);

    // Dropdown -> 'Cancelled'
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelled').last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('Buy dinner'), findsOneWidget);

    // Tapping a DashboardBountyCard triggers onSelectBounty
    await tester.tap(find.text('Buy dinner'));
    await tester.pump();
    expect(tappedBounty?.id, '7');
  });

  testWidgets('DashboardView and ChoresView render outer background container only when section/filter has no chores',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      role: 'owner',
    );

    final openBounty = Bounty(
      id: '10',
      householdId: '2',
      creatorId: '2',
      creator: 'Leonard Hofstadter',
      title: 'Buy dinner',
      category: 'Groceries',
      points: 50,
      status: 'open',
    );

    final sectionBgFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFF8FAFC) &&
            box.borderRadius == BorderRadius.circular(20);
      }
      return false;
    });

    // 1. DashboardView with 1 available chore and 0 ongoing chores:
    // Available Chores has NO outer background container; empty My Chores HAS 1 background container.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardView(
            user: currentUser,
            currentHousehold: household,
            bounties: [openBounty],
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

    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(find.text('No ongoing chores'), findsOneWidget);
    expect(sectionBgFinder, findsOneWidget);

    // 2. ChoresView: 'Available' has 1 chore (0 background containers), 'In Progress' has 0 chores (1 background container)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChoresView(
            user: currentUser,
            currentHousehold: household,
            bounties: [openBounty],
            isLoading: false,
            onRefresh: () async {},
            onSelectBounty: (_) {},
            onCreateBounty: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DashboardBountyCard), findsOneWidget);
    expect(sectionBgFinder, findsNothing);

    await tester.tap(find.text('In Progress'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardBountyCard), findsNothing);
    expect(find.text('No chores in progress'), findsOneWidget);
    expect(sectionBgFinder, findsOneWidget);
  });

  testWidgets('Overdue open bounties are excluded from Available and shown under Past Due filter and details',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      role: 'owner',
    );
    final now = DateTime.now();

    final otherFutureBounty = Bounty(
      id: '10',
      householdId: '2',
      creatorId: '2',
      creator: 'Leonard Hofstadter',
      title: 'Fresh Chore',
      category: 'Cleaning',
      points: 30,
      status: 'open',
      dueAt: now.add(const Duration(hours: 3)),
    );
    final otherPastDueBounty = Bounty(
      id: '11',
      householdId: '2',
      creatorId: '2',
      creator: 'Leonard Hofstadter',
      title: 'Overdue Roommate Chore',
      category: 'Cleaning',
      points: 40,
      status: 'open',
      dueAt: now.subtract(const Duration(hours: 1)),
    );
    final myPastDueBounty = Bounty(
      id: '12',
      householdId: '2',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      title: 'Test Overdue Posted',
      category: 'Other',
      points: 50,
      status: 'open',
      dueAt: now.subtract(const Duration(minutes: 10)),
    );
    final myFutureBounty = Bounty(
      id: '13',
      householdId: '2',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      title: 'My Available Chore',
      category: 'Other',
      points: 20,
      status: 'open',
      dueAt: now.add(const Duration(hours: 5)),
    );

    // 1. DashboardView excludes overdue bounties from Available Chores
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardView(
            user: currentUser,
            currentHousehold: household,
            bounties: [
              otherFutureBounty,
              otherPastDueBounty,
              myPastDueBounty,
            ],
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

    expect(find.text('Fresh Chore'), findsOneWidget);
    expect(find.text('Overdue Roommate Chore'), findsNothing);
    expect(find.text('Test Overdue Posted'), findsNothing);

    // 2. ChoresView hides overdue from Available and filters it under Posted by Me -> Past Due
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChoresView(
            user: currentUser,
            currentHousehold: household,
            bounties: [
              otherFutureBounty,
              otherPastDueBounty,
              myPastDueBounty,
              myFutureBounty,
            ],
            isLoading: false,
            onRefresh: () async {},
            onSelectBounty: (_) {},
            onCreateBounty: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Fresh Chore'), findsOneWidget);
    expect(find.text('Overdue Roommate Chore'), findsNothing);

    await tester.tap(find.text('Posted by Me'));
    await tester.pumpAndSettle();

    // Open status dropdown -> select Available (must exclude myPastDueBounty)
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Available').last);
    await tester.pumpAndSettle();

    expect(find.text('My Available Chore'), findsOneWidget);
    expect(find.text('Test Overdue Posted'), findsNothing);

    // Open status dropdown -> select Past Due (must show myPastDueBounty with Past Due chip)
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Past Due').last);
    await tester.pumpAndSettle();

    expect(find.text('Test Overdue Posted'), findsOneWidget);
    expect(find.text('My Available Chore'), findsNothing);
    expect(find.text('Past Due'), findsWidgets);

    // 3. BountyDetailScreen for non-creator shows Past Due badge & banner, no Claim button
    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('past_due_non_creator'),
          bounty: otherPastDueBounty,
          currentUser: currentUser,
          service: _FakeShowBountyService(otherPastDueBounty),
          refreshOnOpen: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Past Due'), findsNWidgets(2));
    expect(find.text('Claim This Bounty'), findsNothing);

    // 4. BountyDetailScreen for creator shows Past Due badge and keeps Edit/Cancel/Delete in one row
    final creatorService = _FakeShowBountyService(myPastDueBounty);
    await tester.pumpWidget(
      MaterialApp(
        home: BountyDetailScreen(
          key: const ValueKey('past_due_creator'),
          bounty: myPastDueBounty,
          currentUser: currentUser,
          service: creatorService,
          refreshOnOpen: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Past Due'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Cancel')).dy,
      tester.getTopLeft(find.text('Edit')).dy,
    );
    expect(
      tester.getTopLeft(find.text('Delete')).dy,
      tester.getTopLeft(find.text('Edit')).dy,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Bounty'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(creatorService.deletedIds, ['12']);
  });

  testWidgets('DashboardBountyCard reflects Taken, Past Due, Cancelled, and Completed in status chip',
      (WidgetTester tester) async {
    final expiredAt = DateTime.now().subtract(const Duration(hours: 2));
    final futureAt = DateTime.now().add(const Duration(days: 2));

    final takenClaimedBounty = Bounty(
      id: '19',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      assigneeId: '2',
      assignee: 'Leonard',
      title: 'Do the laundry',
      points: 50,
      status: 'claimed',
      dueAt: futureAt,
    );
    final takenSubmittedBounty = Bounty(
      id: '19b',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      assigneeId: '2',
      assignee: 'Leonard',
      title: 'Sweep hallway',
      points: 30,
      status: 'submitted',
      dueAt: futureAt,
    );
    final pastDueBounty = Bounty(
      id: '20',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      title: 'Test Overdue',
      points: 50,
      status: 'open',
      dueAt: expiredAt,
    );
    final cancelledBounty = Bounty(
      id: '21',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      title: 'Buy dinner',
      points: 50,
      status: 'cancelled',
      dueAt: expiredAt,
    );
    final completedBounty = Bounty(
      id: '22',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      title: 'Clean the room',
      points: 50,
      status: 'completed',
      dueAt: expiredAt,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DashboardBountyCard(
                  bounty: takenClaimedBounty,
                  currentUserId: '1',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
                DashboardBountyCard(
                  bounty: takenSubmittedBounty,
                  currentUserId: '1',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
                DashboardBountyCard(
                  bounty: pastDueBounty,
                  currentUserId: '1',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
                DashboardBountyCard(
                  bounty: cancelledBounty,
                  currentUserId: '1',
                  currentUserName: 'Sheldon Cooper',
                  onTap: () {},
                ),
                DashboardBountyCard(
                  bounty: completedBounty,
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
    await tester.pump();

    expect(find.text('Taken'), findsNWidgets(2));
    expect(find.text('Past Due'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('0 Seconds'), findsNothing);
    expect(find.textContaining('2 Days'), findsNothing);
  });

  testWidgets('ChoresView uses Profile-style PageMenuHeader and HomeShell drawer uses Active Household dropdown',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );
    const householdA = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      role: 'owner',
    );
    const householdB = Household(
      id: 3,
      name: 'Beach Loft',
      inviteCode: 'BEACH',
      role: 'member',
    );

    // 1. ChoresView header matches PageMenuHeader without subtitle
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChoresView(
            user: currentUser,
            currentHousehold: householdA,
            bounties: const [],
            isLoading: false,
            onRefresh: () async {},
            onSelectBounty: (_) {},
            onCreateBounty: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageMenuHeader), findsOneWidget);
    expect(find.text('Bounties'), findsOneWidget);
    expect(find.textContaining('Browse and manage chores'), findsNothing);

    // 2. HomeShell drawer replaces Switch Household with Active Household dropdown
    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: AuthService(api, storage),
          bounties: _FakeHomeBountyService(),
          households: _FakeHouseholdService([householdA, householdB]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Switch Household'), findsNothing);
    expect(find.text('Active Household'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beach Loft').last);
    await tester.pumpAndSettle();

    expect(storage.savedHouseholdId, '3');
    expect(find.text('Switched to Beach Loft!'), findsOneWidget);
  });

  testWidgets('Drawer places Household between Leaderboard and Profile, and Household page renders member count with owner first',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 2,
      name: 'Leonard Hofstadter',
      firstName: 'Leonard',
      lastName: 'Hofstadter',
      gender: 'male',
      email: 'leonard@gmail.com',
      avatar: 'guy_2',
    );
    const householdA = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'member',
      membersCount: 3,
    );

    final membersByHousehold = <int, List<HouseholdMember>>{
      2: [
        const HouseholdMember(
          userId: 2,
          name: 'Leonard Hofstadter',
          email: 'leonard@gmail.com',
          avatar: 'guy_2',
          role: 'member',
        ),
        const HouseholdMember(
          userId: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@gmail.com',
          avatar: 'guy_1',
          role: 'owner',
        ),
        const HouseholdMember(
          userId: 3,
          name: 'Howard Wolowitz',
          email: 'howard@gmail.com',
          avatar: 'guy_3',
          role: 'member',
        ),
      ],
    };

    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: AuthService(api, storage),
          bounties: _FakeHomeBountyService(
            leaderboardList: const [
              LeaderboardEntry(
                rank: 1,
                userId: 1,
                name: 'Sheldon Cooper',
                avatarUrl: 'guy_1',
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
                avatarUrl: 'guy_2',
                completedCount: 1,
                activeCount: 0,
                totalTokens: 50,
                totalRewardValue: 50,
                tier: 'Household Novice',
              ),
            ],
          ),
          households: _FakeHouseholdService(
            [householdA],
            membersByHousehold: membersByHousehold,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open drawer and check ordering: Leaderboard -> Guild -> Profile
    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Bounties'), findsOneWidget);
    final leaderboardY = tester.getTopLeft(find.text('Leaderboard')).dy;
    final guildY = tester.getTopLeft(find.text('Guild')).dy;
    final profileY = tester.getTopLeft(find.text('Profile')).dy;
    expect(guildY, greaterThan(leaderboardY));
    expect(profileY, greaterThan(guildY));

    // Navigate to Guild page
    await tester.tap(find.text('Guild'));
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdView), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
    expect(find.text('Roommates'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Member'), findsNWidgets(2));
    expect(find.text('150 tokens'), findsOneWidget);
    expect(find.text('3 bounties'), findsOneWidget);
    expect(find.text('50 tokens'), findsOneWidget);
    expect(find.text('1 bounty'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) {
          if (w is! Image) return false;
          final provider = w.image is ResizeImage
              ? (w.image as ResizeImage).imageProvider
              : w.image;
          return provider is AssetImage &&
              provider.assetName == 'assets/images/home_icon.png';
        },
      ),
      findsOneWidget,
    );

    // Verify owner is rendered above regular members
    final ownerY = tester.getTopLeft(find.text('Sheldon Cooper')).dy;
    final member1Y = tester.getTopLeft(find.text('Leonard Hofstadter (You)')).dy;
    final member2Y = tester.getTopLeft(find.text('Howard Wolowitz')).dy;
    expect(ownerY, lessThan(member1Y));
    expect(member1Y, lessThan(member2Y));
  });

  testWidgets(
      'LeaderboardView uses PageMenuHeader, removes badges, shows podium and ordinal list, and opens UserDetailScreen on user tap',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 2,
      name: 'Leonard Hofstadter',
      firstName: 'Leonard',
      lastName: 'Hofstadter',
      gender: 'male',
      email: 'leonard@gmail.com',
      avatar: 'guy_2',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'member',
      membersCount: 4,
    );

    const entries = [
      LeaderboardEntry(
        rank: 1,
        userId: 1,
        name: 'Sheldon Cooper',
        avatarUrl: 'guy_1',
        completedCount: 4,
        activeCount: 1,
        totalTokens: 200,
        totalRewardValue: 200,
        tier: 'Apprentice Sweeper',
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 2,
        name: 'Leonard Hofstadter',
        avatarUrl: 'guy_2',
        completedCount: 2,
        activeCount: 1,
        totalTokens: 120,
        totalRewardValue: 120,
        tier: 'Household Novice',
      ),
      LeaderboardEntry(
        rank: 3,
        userId: 3,
        name: 'Howard Wolowitz',
        avatarUrl: 'guy_3',
        completedCount: 1,
        activeCount: 0,
        totalTokens: 50,
        totalRewardValue: 50,
        tier: 'Household Novice',
      ),
      LeaderboardEntry(
        rank: 4,
        userId: 4,
        name: 'Raj Koothrappali',
        avatarUrl: 'guy_4',
        completedCount: 0,
        activeCount: 0,
        totalTokens: 0,
        totalRewardValue: 0,
        tier: 'Household Novice',
      ),
    ];

    final bounties = [
      const Bounty(
        id: '10',
        householdId: '2',
        creatorId: '2',
        creator: 'Leonard Hofstadter',
        assigneeId: '1',
        assignee: 'Sheldon Cooper',
        title: 'Sanitize kitchen counters',
        category: 'Kitchen',
        points: 50,
        status: 'completed',
      ),
      const Bounty(
        id: '11',
        householdId: '2',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        assigneeId: '3',
        assignee: 'Howard Wolowitz',
        title: 'Take out recycling',
        category: 'Trash',
        points: 30,
        status: 'claimed',
      ),
    ];

    final membersByHousehold = <int, List<HouseholdMember>>{
      2: [
        const HouseholdMember(
          userId: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@gmail.com',
          avatar: 'guy_1',
          role: 'owner',
        ),
        const HouseholdMember(
          userId: 2,
          name: 'Leonard Hofstadter',
          email: 'leonard@gmail.com',
          avatar: 'guy_2',
          role: 'member',
        ),
        const HouseholdMember(
          userId: 3,
          name: 'Howard Wolowitz',
          email: 'howard@gmail.com',
          avatar: 'guy_3',
          role: 'member',
        ),
        const HouseholdMember(
          userId: 4,
          name: 'Raj Koothrappali',
          email: 'raj@gmail.com',
          avatar: 'guy_4',
          role: 'member',
        ),
      ],
    };

    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: AuthService(api, storage),
          bounties: _FakeHomeBountyService(
            bountiesList: bounties,
            leaderboardList: entries,
          ),
          households: _FakeHouseholdService(
            [household],
            membersByHousehold: membersByHousehold,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open drawer and navigate to Leaderboard
    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    // 1. Header matches PageMenuHeader style (no badges, no period pills)
    expect(find.byType(PageMenuHeader), findsWidgets);
    expect(find.text('Leaderboard'), findsWidgets);
    expect(find.text('My Badges'), findsNothing);
    expect(find.text('First Clean'), findsNothing);
    expect(find.text('This Week'), findsNothing);
    expect(find.text('This Month'), findsNothing);

    // 2. Ranked list cards show ordinal ranks 1st, 2nd, 3rd, 4th
    expect(find.text('1st'), findsOneWidget);
    expect(find.text('2nd'), findsOneWidget);
    expect(find.text('3rd'), findsOneWidget);
    expect(find.text('4th'), findsOneWidget);
    expect(find.text('Leonard Hofstadter (You)'), findsOneWidget);

    // 3. Podium first-place card is higher up/taller than 2nd, and 2nd above 3rd baseline check via top Y
    final sheldonPodiumY = tester.getTopLeft(find.text('Sheldon')).dy;
    final leonardPodiumY = tester.getTopLeft(find.text('Leonard')).dy;
    final howardPodiumY = tester.getTopLeft(find.text('Howard')).dy;
    expect(sheldonPodiumY, lessThan(leonardPodiumY));
    expect(leonardPodiumY, lessThan(howardPodiumY));

    // 4. Tap Sheldon Cooper in the list to open dedicated UserDetailScreen
    await tester.tap(find.text('Sheldon Cooper'));
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Sheldon Cooper'), findsOneWidget);
    expect(find.text('sheldon@gmail.com'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('1st'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('Sanitize kitchen counters'), findsOneWidget);

    // Switch chore activity filter to Posted
    await tester.tap(find.text('Posted'));
    await tester.pumpAndSettle();
    expect(find.text('Take out recycling'), findsOneWidget);
  });

  testWidgets(
      'Tapping own profile in Leaderboard redirects to redesigned ProfileView with User Profile layout and styled households section',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 2,
      name: 'Leonard Hofstadter',
      firstName: 'Leonard',
      lastName: 'Hofstadter',
      gender: 'male',
      email: 'leonard@gmail.com',
      avatar: 'guy_2',
    );
    const householdA = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'member',
      membersCount: 2,
    );
    const householdB = Household(
      id: 3,
      name: 'Beach Loft',
      inviteCode: 'BEACH',
      createdBy: 2,
      role: 'owner',
      membersCount: 1,
    );

    const entries = [
      LeaderboardEntry(
        rank: 1,
        userId: 1,
        name: 'Sheldon Cooper',
        avatarUrl: 'guy_1',
        completedCount: 3,
        activeCount: 0,
        totalTokens: 150,
        totalRewardValue: 150,
        tier: 'Household Novice',
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 2,
        name: 'Leonard Hofstadter',
        avatarUrl: 'guy_2',
        completedCount: 1,
        activeCount: 0,
        totalTokens: 50,
        totalRewardValue: 50,
        tier: 'Household Novice',
      ),
    ];

    final bounties = [
      const Bounty(
        id: '20',
        householdId: '2',
        creatorId: '1',
        creator: 'Sheldon Cooper',
        assigneeId: '2',
        assignee: 'Leonard Hofstadter',
        title: 'Clean the room',
        category: 'Cleaning',
        points: 50,
        status: 'completed',
      ),
    ];

    final membersByHousehold = <int, List<HouseholdMember>>{
      2: [
        const HouseholdMember(
          userId: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@gmail.com',
          avatar: 'guy_1',
          role: 'owner',
        ),
        const HouseholdMember(
          userId: 2,
          name: 'Leonard Hofstadter',
          email: 'leonard@gmail.com',
          avatar: 'guy_2',
          role: 'member',
        ),
      ],
    };

    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: AuthService(api, storage),
          bounties: _FakeHomeBountyService(
            bountiesList: bounties,
            leaderboardList: entries,
          ),
          households: _FakeHouseholdService(
            [householdA, householdB],
            membersByHousehold: membersByHousehold,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Leaderboard
    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    // Tap own row ("Leonard Hofstadter (You)") -> should redirect to ProfileView instead of UserDetailScreen
    await tester.tap(find.text('Leonard Hofstadter (You)'));
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsNothing);
    expect(find.byType(ProfileView), findsOneWidget);
    expect(find.text('Change Avatar'), findsNothing);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.text('Chore Activity'), findsOneWidget);
    expect(find.text('Clean the room'), findsOneWidget);
    expect(find.text('2nd'), findsOneWidget);

    final profileScrollable = find
        .descendant(
          of: find.byType(ProfileView),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.text('My Households'),
      300,
      scrollable: profileScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('My Households'), findsOneWidget);
    expect(find.text('APT4A'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Log out'),
      300,
      scrollable: profileScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Leave Household'), findsNWidgets(2));
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets(
      'HouseholdPromptScreen omits welcome banner and provides working back button',
      (WidgetTester tester) async {
    const user = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      email: 'sheldon@gmail.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HouseholdPromptScreen(
                        user: user,
                        isOptional: true,
                      ),
                    ),
                  );
                },
                child: const Text('Open Setup'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdPromptScreen), findsOneWidget);
    expect(find.text('Household Setup'), findsOneWidget);
    expect(find.textContaining('Welcome,'), findsNothing);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdPromptScreen), findsNothing);
    expect(find.text('Open Setup'), findsOneWidget);
  });

  testWidgets(
      'Tapping edit icon on ProfileView opens EditProfileScreen and saves updated profile',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 2,
      name: 'Leonard Hofstadter',
      firstName: 'Leonard',
      lastName: 'Hofstadter',
      gender: 'male',
      email: 'leonard@gmail.com',
      avatar: 'guy_2',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'member',
      membersCount: 2,
    );

    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);
    final fakeAuth = _FakeEditAuthService(api, storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: fakeAuth,
          bounties: _FakeHomeBountyService(),
          households: _FakeHouseholdService([household]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Profile tab via drawer
    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileView), findsOneWidget);
    expect(find.text('Change Avatar'), findsNothing);

    // Tap the edit icon on the avatar
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);

    final editScrollable = find
        .descendant(
          of: find.byType(EditProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;

    // Select another avatar, scroll to name fields, update first/middle/last/gender, and save
    await tester.tap(find.text('Guy 3'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Last Name'),
      200,
      scrollable: editScrollable,
    );
    final fields = find.descendant(
      of: find.byType(EditProfileScreen),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'Leonard');
    await tester.enterText(fields.at(1), 'Leakey');
    await tester.enterText(fields.at(2), 'Hofstadter');

    await tester.scrollUntilVisible(
      find.text('Save Changes'),
      200,
      scrollable: editScrollable,
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(fakeAuth.lastSavedName, 'Leonard Leakey Hofstadter');
    expect(fakeAuth.lastSavedGender, 'male');
    expect(fakeAuth.lastSavedAvatar, 'guy_3');
    expect(find.text('Leonard Leakey Hofstadter'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Leonard Leakey Hofstadter (You)'), findsNothing);
  });

  testWidgets(
      'BountyDetailScreen avatar tap opens UserDetailScreen for other users and ProfileView for current user',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 2,
      name: 'Leonard Hofstadter',
      firstName: 'Leonard',
      lastName: 'Hofstadter',
      gender: 'male',
      email: 'leonard@gmail.com',
      avatar: 'guy_2',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'member',
      membersCount: 2,
    );

    final bounty = Bounty(
      id: '30',
      householdId: '2',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      creatorAvatar: 'guy_1',
      assigneeId: '2',
      assignee: 'Leonard Hofstadter',
      assigneeAvatar: 'guy_2',
      title: 'Do the laundry',
      category: 'Laundry',
      points: 50,
      status: 'claimed',
      claimedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final membersByHousehold = <int, List<HouseholdMember>>{
      2: [
        const HouseholdMember(
          userId: 1,
          name: 'Sheldon Cooper',
          email: 'sheldon@gmail.com',
          avatar: 'guy_1',
          role: 'owner',
        ),
        const HouseholdMember(
          userId: 2,
          name: 'Leonard Hofstadter',
          email: 'leonard@gmail.com',
          avatar: 'guy_2',
          role: 'member',
        ),
      ],
    };

    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: AuthService(api, storage),
          bounties: _FakeHomeBountyService(bountiesList: [bounty]),
          households: _FakeHouseholdService(
            [household],
            membersByHousehold: membersByHousehold,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open BountyDetailScreen from dashboard
    await tester.tap(find.text('Do the laundry'));
    await tester.pumpAndSettle();
    expect(find.byType(BountyDetailScreen), findsOneWidget);

    // Tap poster avatar (Sheldon Cooper, id 1) -> opens UserDetailScreen
    final bountyAvatars = find.descendant(
      of: find.byType(BountyDetailScreen),
      matching: find.byType(UserAvatarWidget),
    );
    expect(bountyAvatars, findsOneWidget);
    await tester.tap(bountyAvatars.first);
    await tester.pumpAndSettle();

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(find.text('Sheldon Cooper'), findsOneWidget);

    // Return to BountyDetailScreen
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(BountyDetailScreen), findsOneWidget);

    // Scroll down to Claimed by card and tap claimant avatar (Leonard Hofstadter, currentUser id 2) -> redirects to ProfileView
    await tester.scrollUntilVisible(
      find.text('Claimed by'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(BountyDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(bountyAvatars.last);
    await tester.pumpAndSettle();

    expect(find.byType(BountyDetailScreen), findsNothing);
    expect(find.byType(UserDetailScreen), findsNothing);
    expect(find.byType(ProfileView), findsOneWidget);
    expect(find.text('Leonard Hofstadter'), findsWidgets);
    expect(find.text('Leonard Hofstadter (You)'), findsNothing);
  });

  testWidgets(
      'Notification bell opens pending review notifications instead of My Households, and creator can reject submitted proof',
      (WidgetTester tester) async {
    const currentUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      firstName: 'Sheldon',
      lastName: 'Cooper',
      gender: 'male',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'owner',
      membersCount: 2,
    );
    final submittedBounty = Bounty(
      id: '99',
      householdId: '2',
      creatorId: '1',
      creator: 'Sheldon Cooper',
      assigneeId: '2',
      assignee: 'Leonard Hofstadter',
      title: 'Mop kitchen floor',
      category: 'Cleaning',
      points: 45,
      status: 'submitted',
      submissionProof: 'Mopped quickly',
      claimedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final bountyService = _FakeHomeBountyService(
      bountiesList: [submittedBounty],
    );
    final storage = _FakeTokenStorage();
    final api = ApiClient(storage);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: currentUser,
          auth: AuthService(api, storage),
          bounties: bountyService,
          households: _FakeHouseholdService([household]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap bell icon -> should open Notifications bottom sheet (not My Households)
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Awaiting Your Review'), findsOneWidget);
    expect(find.text('Mop kitchen floor'), findsWidgets);
    expect(find.text('My Households'), findsNothing);

    // Tap notification item -> opens BountyDetailScreen with Approve & Request Redo
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.byType(BountyDetailScreen), findsOneWidget);
    expect(find.text('Pending Review'), findsOneWidget);
    expect(find.text('Approve & Disburse Reward'), findsOneWidget);
    expect(find.text('Request Redo'), findsOneWidget);

    // Tap Request Redo -> confirm dialog -> invokes BountyService.reject
    await tester.tap(find.text('Request Redo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Missed corners',
    );
    await tester.tap(find.text('Request Redo').last);
    await tester.pumpAndSettle();

    expect(bountyService.rejectedIds, ['99']);
    expect(bountyService.lastRejectFeedback, 'Missed corners');
  });

  testWidgets(
      'ChoresView provides header Post button and search filter, and HouseholdView supports guild rename & member removal',
      (WidgetTester tester) async {
    const ownerUser = AppUser(
      id: 1,
      name: 'Sheldon Cooper',
      firstName: 'Sheldon',
      lastName: 'Cooper',
      gender: 'male',
      email: 'sheldon@gmail.com',
      avatar: 'guy_1',
    );
    const household = Household(
      id: 2,
      name: 'Apartment 4A',
      inviteCode: 'APT4A',
      createdBy: 1,
      role: 'owner',
      membersCount: 2,
    );
    final bounties = [
      Bounty(
        id: '101',
        householdId: '2',
        creatorId: '2',
        creator: 'Leonard Hofstadter',
        title: 'Vacuum living room',
        category: 'Cleaning',
        points: 40,
        status: 'open',
      ),
      Bounty(
        id: '102',
        householdId: '2',
        creatorId: '2',
        creator: 'Leonard Hofstadter',
        title: 'Buy coffee beans',
        category: 'Groceries',
        points: 25,
        status: 'open',
      ),
    ];

    bool createTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChoresView(
            user: ownerUser,
            currentHousehold: household,
            bounties: bounties,
            isLoading: false,
            onRefresh: () async {},
            onSelectBounty: (_) {},
            onCreateBounty: () => createTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Header + Post quick action works when list is non-empty
    expect(find.text('Post'), findsOneWidget);
    await tester.tap(find.text('Post'));
    await tester.pump();
    expect(createTapped, isTrue);

    // Search filter narrows down bounties by title
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();

    expect(find.text('Buy coffee beans'), findsOneWidget);
    expect(find.text('Vacuum living room'), findsNothing);

    // HouseholdView owner actions: rename guild + remove member
    String? renamedTo;
    HouseholdMember? removedMember;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HouseholdView(
            currentUser: ownerUser,
            currentHousehold: household,
            members: const [
              HouseholdMember(
                userId: 1,
                name: 'Sheldon Cooper',
                email: 'sheldon@gmail.com',
                role: 'owner',
              ),
              HouseholdMember(
                userId: 2,
                name: 'Leonard Hofstadter',
                email: 'leonard@gmail.com',
                role: 'member',
              ),
            ],
            isLoading: false,
            onRefresh: () async {},
            onRenameHousehold: (_, newName) async => renamedTo = newName,
            onRemoveMember: (_, member) async => removedMember = member,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Rename guild'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Guild 4A',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(renamedTo, 'Guild 4A');

    await tester.tap(find.byTooltip('Remove member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(removedMember?.userId, 2);
  });
}

class _FakeEditAuthService extends AuthService {
  _FakeEditAuthService(super.api, super.storage);

  String? lastSavedName;
  String? lastSavedGender;
  String? lastSavedAvatar;

  @override
  Future<AppUser> updateProfile({
    required int userId,
    required String firstName,
    String? middleName,
    required String lastName,
    required String gender,
    String? avatar,
  }) async {
    final composed = AppUser.composeFullName(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
    );
    lastSavedName = composed;
    lastSavedGender = gender;
    lastSavedAvatar = avatar;
    return AppUser(
      id: userId,
      name: composed,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      gender: gender,
      email: 'leonard@gmail.com',
      avatar: avatar,
    );
  }
}

class _FakeShowBountyService extends BountyService {
  _FakeShowBountyService(this._bounty) : super(ApiClient(TokenStorage()));

  final Bounty _bounty;
  final List<String> deletedIds = [];

  @override
  Future<Bounty> show(String id) async => _bounty;

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
  }
}

class _FakeTokenStorage extends TokenStorage {
  String? savedHouseholdId;

  @override
  Future<String?> read() async => 'fake-token';

  @override
  Future<String?> readHouseholdId() async => savedHouseholdId;

  @override
  Future<void> saveHouseholdId(String id) async {
    savedHouseholdId = id;
  }

  @override
  Future<String?> readAvatar() async => null;
}

class _FakeHouseholdService extends HouseholdService {
  _FakeHouseholdService(
    this._list, {
    this.membersByHousehold = const {},
  }) : super(ApiClient(_FakeTokenStorage()));

  final List<Household> _list;
  final Map<int, List<HouseholdMember>> membersByHousehold;

  @override
  Future<List<Household>> all() async => _list;

  @override
  Future<List<HouseholdMember>> members(int householdId) async {
    return HouseholdMember.sortOwnerFirst(
      membersByHousehold[householdId] ?? const [],
    );
  }
}

class _FakeHomeBountyService extends BountyService {
  _FakeHomeBountyService({
    this.bountiesList = const [],
    this.leaderboardList = const [],
  }) : super(ApiClient(_FakeTokenStorage()));

  final List<Bounty> bountiesList;
  final List<LeaderboardEntry> leaderboardList;
  final List<String> rejectedIds = [];
  String? lastRejectFeedback;

  @override
  Future<List<Bounty>> all({
    String? status,
    String? householdId,
    int perPage = 100,
  }) async => bountiesList;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? householdId,
    String? period,
  }) async => leaderboardList;

  @override
  Future<void> reject(String id, {String? feedback}) async {
    rejectedIds.add(id);
    lastRejectFeedback = feedback;
  }
}
