import 'package:chore_bounty_application/models/app_user.dart';
import 'package:chore_bounty_application/models/bounty.dart';
import 'package:chore_bounty_application/models/household.dart';
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
        'creator': {'name': 'Sarah Connor'},
        'assignee': {'name': 'Alex Mercer'},
      };

      final bounty = Bounty.fromJson(json);

      expect(bounty.id, '14');
      expect(bounty.title, 'Defeat Mount Dishmore');
      expect(bounty.difficulty, 'epic');
      expect(bounty.xpReward, 250);
      expect(bounty.rewardValue, 15.00);
      expect(bounty.reward, '1 Venti Oat Latte');
      expect(bounty.creator, 'Sarah Connor');
      expect(bounty.assignee, 'Alex Mercer');
      expect(bounty.isOpen, isTrue);
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
        'total_xp': 750,
        'total_reward_value': 45.00,
        'tier': 'Chore Knight',
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.rank, 1);
      expect(entry.userId, 3);
      expect(entry.name, 'Alex Mercer');
      expect(entry.completedCount, 5);
      expect(entry.totalXp, 750);
      expect(entry.totalRewardValue, 45.00);
      expect(entry.tier, 'Chore Knight');
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
  });
}
