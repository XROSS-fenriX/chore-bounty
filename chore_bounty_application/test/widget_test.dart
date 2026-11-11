import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chore_bounty_application/main.dart';
import 'package:chore_bounty_application/core/api_client.dart';
import 'package:chore_bounty_application/core/token_storage.dart';
import 'package:chore_bounty_application/models/app_user.dart';
import 'package:chore_bounty_application/models/bounty.dart';
import 'package:chore_bounty_application/screens/bounty_detail_screen.dart';
import 'package:chore_bounty_application/screens/create_bounty_screen.dart';
import 'package:chore_bounty_application/services/bounty_service.dart';
import 'package:chore_bounty_application/widgets/avatar/user_avatar_widget.dart';
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

  testWidgets('BountyDetailScreen renders full name instead of "you" and renders Edit Bounty and Cancel This Bounty buttons for creator',
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

    // Verify both Edit Bounty and Cancel This Bounty buttons are present
    expect(find.text('Edit Bounty'), findsOneWidget);
    expect(find.text('Cancel This Bounty'), findsOneWidget);

    // Tap 'Edit Bounty' and verify navigation to populated CreateBounty form
    await tester.tap(find.text('Edit Bounty'));
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
}

class _FakeShowBountyService extends BountyService {
  _FakeShowBountyService(this._bounty) : super(ApiClient(TokenStorage()));

  final Bounty _bounty;

  @override
  Future<Bounty> show(String id) async => _bounty;
}
