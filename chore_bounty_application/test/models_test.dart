import 'package:chore_bounty_application/models/app_user.dart';
import 'package:chore_bounty_application/models/bounty.dart';
import 'package:chore_bounty_application/models/household.dart';
import 'package:chore_bounty_application/models/household_member.dart';
import 'package:chore_bounty_application/models/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bounty Model Tests', () {
    test('Correctly parses API json with quest attributes', () {
      final json = {
        'id': 14,
        'household_id': 2,
        'creator_id': 1,
        'assignee_id': 3,
        'title': 'Defeat Mount Dishmore',
        'description': 'Wash all pots and pans',
        'difficulty': 'epic',
        'xp_reward': 250,
        'reward_value': 15.00,
        'reward_description': '1 Venti Oat Latte',
        'status': 'open',
        'creator': {'name': 'Sarah Connor', 'avatar': 'gal_1'},
        'assignee': {'name': 'Alex Mercer', 'avatar': 'guy_2'},
      };

      final bounty = Bounty.fromJson(json);

      expect(bounty.id, '14');
      expect(bounty.title, 'Defeat Mount Dishmore');
      expect(bounty.difficulty, 'epic');
      expect(bounty.xpReward, 250);
      expect(bounty.rewardValue, 15.00);
      expect(bounty.reward, '1 Venti Oat Latte');
      expect(bounty.creator, 'Sarah Connor');
      expect(bounty.creatorAvatar, 'gal_1');
      expect(bounty.assignee, 'Alex Mercer');
      expect(bounty.assigneeAvatar, 'guy_2');
      expect(bounty.isOpen, isTrue);
    });

    test('Falls back to claims user avatar when assignee object is omitted', () {
      final json = {
        'id': 15,
        'household_id': 2,
        'creator_id': 1,
        'title': 'Do the laundry',
        'status': 'claimed',
        'creator': {'name': 'Sheldon Cooper', 'avatar_id': 'guy_1'},
        'claims': [
          {
            'user_id': 2,
            'status': 'active',
            'user': {'id': 2, 'name': 'Leonard Hofstadter', 'avatar': 'guy_2'},
          }
        ],
      };

      final bounty = Bounty.fromJson(json);

      expect(bounty.creatorAvatar, 'guy_1');
      expect(bounty.assigneeId, '2');
      expect(bounty.assignee, 'Leonard Hofstadter');
      expect(bounty.assigneeAvatar, 'guy_2');
    });

    test('Classifies overdue open bounties as Past Due and not Available', () {
      final pastDueOpen = Bounty(
        id: '1',
        householdId: '1',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Test',
        status: 'open',
        dueAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final futureOpen = Bounty(
        id: '2',
        householdId: '1',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Future chore',
        status: 'open',
        dueAt: DateTime.now().add(const Duration(hours: 2)),
      );
      final noDueDateOpen = Bounty(
        id: '3',
        householdId: '1',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Undated chore',
        status: 'open',
      );
      final pastDueCompleted = Bounty(
        id: '4',
        householdId: '1',
        creatorId: '1',
        creator: 'Sheldon',
        title: 'Done chore',
        status: 'completed',
        dueAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(pastDueOpen.isOpen, isTrue);
      expect(pastDueOpen.isPastDue, isTrue);
      expect(pastDueOpen.isAvailable, isFalse);

      expect(futureOpen.isPastDue, isFalse);
      expect(futureOpen.isAvailable, isTrue);

      expect(noDueDateOpen.isPastDue, isFalse);
      expect(noDueDateOpen.isAvailable, isTrue);

      expect(pastDueCompleted.isPastDue, isFalse);
      expect(pastDueCompleted.isAvailable, isFalse);
    });
  });

  group('LeaderboardEntry Model Tests', () {
    test('Correctly parses household leaderboard record', () {
      final json = {
        'rank': 1,
        'user_id': 3,
        'name': 'Alex Mercer',
        'avatar_url': null,
        'completed_bounties_count': 5,
        'active_bounties_count': 1,
        'total_tokens': 750,
        'total_xp': 750,
        'total_reward_value': 750.00,
        'tier': 'Chore Knight',
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.rank, 1);
      expect(entry.userId, 3);
      expect(entry.name, 'Alex Mercer');
      expect(entry.completedCount, 5);
      expect(entry.totalTokens, 750);
      expect(entry.totalXp, 750);
      expect(entry.totalRewardValue, 750.00);
      expect(entry.tier, 'Chore Knight');
    });

    test('Correctly parses tokens earned from completed chores instead of experience', () {
      final json = {
        'rank': 2,
        'user_id': 5,
        'name': 'Leonard',
        'completed_bounties_count': 3,
        'active_bounties_count': 0,
        'total_tokens': 100,
        'total_reward_value': 100.0,
        'tier': 'Household Novice',
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.rank, 2);
      expect(entry.totalTokens, 100);
      expect(entry.totalRewardValue, 100.0);
    });
  });

  group('Household & AppUser Multi-Household Tests', () {
    test('Correctly parses multiple households on AppUser', () {
      final userJson = {
        'id': 7,
        'name': 'Alex Mercer',
        'email': 'alex@example.com',
        'households': [
          {
            'id': 1,
            'name': 'Apt 4B - Guild Hall',
            'invite_code': 'GUILD4B',
            'role': 'owner',
            'members_count': 3,
            'bounties_count': 4,
          },
          {
            'id': 2,
            'name': 'Summer Beach Loft',
            'invite_code': 'BEACH26',
            'role': 'member',
            'members_count': 4,
            'bounties_count': 1,
          },
        ],
      };

      final user = AppUser.fromJson(userJson);

      expect(user.id, 7);
      expect(user.hasHouseholds, isTrue);
      expect(user.households.length, 2);
      expect(user.households[0].name, 'Apt 4B - Guild Hall');
      expect(user.households[0].isOwner, isTrue);
      expect(user.households[1].name, 'Summer Beach Loft');
      expect(user.households[1].isOwner, isFalse);
    });

    test('Correctly parses Household model', () {
      final hJson = {
        'id': 10,
        'name': 'Pine Ridge Chalet',
        'invite_code': 'PINERDG',
        'role': 'owner',
        'members_count': 5,
        'bounties_count': 8,
      };

      final h = Household.fromJson(hJson);

      expect(h.id, 10);
      expect(h.name, 'Pine Ridge Chalet');
      expect(h.inviteCode, 'PINERDG');
      expect(h.isOwner, isTrue);
      expect(h.membersCount, 5);
      expect(h.bountiesCount, 8);
    });

    test('User with zero households reports hasHouseholds as false', () {
      final newUserJson = {
        'id': 8,
        'name': 'New Roommate',
        'email': 'new@example.com',
        'households': [],
      };

      final user = AppUser.fromJson(newUserJson);

      expect(user.id, 8);
      expect(user.hasHouseholds, isFalse);
      expect(user.households.isEmpty, isTrue);
    });

    test('Parses HouseholdMember and sorts owners before regular members', () {
      final memberFirst = HouseholdMember.fromJson({
        'user_id': 2,
        'role': 'member',
        'user': {
          'id': 2,
          'name': 'Leonard Hofstadter',
          'email': 'leonard@gmail.com',
          'avatar': 'guy_2',
        },
      });
      final ownerSecond = HouseholdMember.fromJson({
        'user_id': 1,
        'role': 'owner',
        'user': {
          'id': 1,
          'name': 'Sheldon Cooper',
          'email': 'sheldon@gmail.com',
          'avatar': 'guy_1',
        },
      });
      final secondMember = HouseholdMember.fromJson({
        'user_id': 3,
        'role': 'member',
        'user': {
          'id': 3,
          'name': 'Penny',
          'email': 'penny@gmail.com',
          'avatar': 'gal_1',
        },
      });

      final sorted = HouseholdMember.sortOwnerFirst([
        memberFirst,
        ownerSecond,
        secondMember,
      ]);

      expect(sorted.map((m) => m.name).toList(), [
        'Sheldon Cooper',
        'Leonard Hofstadter',
        'Penny',
      ]);
      expect(sorted.first.isOwner, isTrue);
      expect(sorted.last.isOwner, isFalse);
    });

    test('Parses structured first/middle/last name and gender fields across user models', () {
      final appUser = AppUser.fromJson({
        'id': 10,
        'first_name': 'Leonard',
        'middle_name': 'Leakey',
        'last_name': 'Hofstadter',
        'gender': 'male',
        'email': 'leonard@example.com',
      });
      expect(appUser.firstName, 'Leonard');
      expect(appUser.middleName, 'Leakey');
      expect(appUser.lastName, 'Hofstadter');
      expect(appUser.name, 'Leonard Leakey Hofstadter');
      expect(appUser.gender, 'male');
      expect(AppUser.formatGender(appUser.gender), 'Male');

      final member = HouseholdMember.fromJson({
        'user_id': 11,
        'role': 'member',
        'user': {
          'id': 11,
          'first_name': 'Amy',
          'middle_name': 'Farrah',
          'last_name': 'Fowler',
          'gender': 'female',
        },
      });
      expect(member.name, 'Amy Farrah Fowler');
      expect(member.gender, 'female');

      final entry = LeaderboardEntry.fromJson({
        'rank': 1,
        'user_id': 11,
        'first_name': 'Amy',
        'middle_name': 'Farrah',
        'last_name': 'Fowler',
        'gender': 'female',
        'completed_bounties_count': 4,
        'active_bounties_count': 0,
        'total_tokens': 200,
        'total_reward_value': 200.0,
        'tier': 'Apprentice Sweeper',
      });
      expect(entry.name, 'Amy Farrah Fowler');
      expect(entry.gender, 'female');
    });
  });
}
