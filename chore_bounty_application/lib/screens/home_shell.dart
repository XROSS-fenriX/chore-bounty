import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/bounty.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../widgets/ui.dart';
import 'login_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.auth,
    required this.bounties,
    required this.user,
  });

  final AuthService auth;
  final BountyService bounties;
  final AppUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  late Future<List<Bounty>> future;
  String filter = 'Available';

  static const Color primaryGreen = Color(0xFF1E8E4E);
  static const Color bgLight = Color(0xFFF7FAF7);

  @override
  void initState() {
    super.initState();
    future = widget.bounties.all();
  }

  Future<void> refresh() async {
    setState(() {
      future = widget.bounties.all();
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder will display errors
    }
  }

  Future<void> logout() async {
    try {
      await widget.auth.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LoginScreen(auth: widget.auth, bounties: widget.bounties),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to log out: $e')));
    }
  }

  Future<void> create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateBounty(service: widget.bounties)),
    );

    if (created == true && mounted) {
      await refresh();
      setState(() => tab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: [home(), tasks(), leaderboard(), profile()],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: create,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'My Tasks',
                index: 1,
              ),
              const SizedBox(width: 48), // Space for docked center FAB
              _buildNavItem(
                icon: Icons.groups_2_outlined,
                label: 'Leaderboard',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = tab == index;
    final color = isSelected ? primaryGreen : Colors.grey.shade400;

    return InkWell(
      onTap: () => setState(() => tab = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget home() {
    return RefreshIndicator(
      onRefresh: refresh,
      color: primaryGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Enlarged Header Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/default_profile.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      radius: 29,
                      backgroundColor: const Color(0xFFFFDCA5),
                      child: Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4310),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.user.name.split(' ').first}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: refresh,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 28,
                    ),
                    color: Colors.black87,
                    tooltip: 'Notifications',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Enlarged Banner Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2EA763), Color(0xFF1B8A49)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep your space tidy!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete bounties and earn rewards.',
                        style: TextStyle(
                          color: Color(0xFFE2F7EB),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/treasure_chest.png',
                  width: 92,
                  height: 92,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.inventory_2_rounded,
                    size: 64,
                    color: Color(0xFFFFD15C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Full-width Segmented Filter Tabs
          Row(
            children: ['All', 'Available', 'My Tasks'].map((item) {
              final selected = filter == item;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => filter = item),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? primaryGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // List of Bounties
          bountyList(filter),
        ],
      ),
    );
  }

  Widget tasks() {
    return RefreshIndicator(
      onRefresh: refresh,
      color: primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your claimed chores',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          bountyList('My Tasks'),
        ],
      ),
    );
  }

  Widget bountyList(String mode) {
    return FutureBuilder<List<Bounty>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              Text(widget.bounties.error(snapshot.error!)),
              TextButton(onPressed: refresh, child: const Text('Retry')),
            ],
          );
        }

        var items = snapshot.data ?? [];

        if (mode == 'Available') {
          items = items.where((bounty) {
            return [
              'available',
              'open',
              'posted',
            ].contains(bounty.status.toLowerCase());
          }).toList();
        }

        if (mode == 'My Tasks') {
          items = items.where((bounty) {
            return [
              'claimed',
              'active',
              'in_progress',
              'in progress',
            ].contains(bounty.status.toLowerCase());
          }).toList();
        }

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No bounties found yet. Tap + to create one.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: items.map((bounty) {
            return _buildCustomBountyCard(bounty);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCustomBountyCard(Bounty bounty) {
    final title = bounty.title.toLowerCase();

    // Determine matching icon asset and background tint
    String assetPath = 'assets/images/trash_bin.png';
    Color iconBg = const Color(0xFFE2F4EE);

    if (title.contains('trash') || title.contains('bin')) {
      assetPath = 'assets/images/trash_bin.png';
      iconBg = const Color(0xFFD8F2EA);
    } else if (title.contains('clean') ||
        title.contains('kitchen') ||
        title.contains('sweep')) {
      assetPath = 'assets/images/broom_stick.png';
      iconBg = const Color(0xFFFFF1D6);
    } else if (title.contains('laundry') || title.contains('wash')) {
      assetPath = 'assets/images/washing_machine.png';
      iconBg = const Color(0xFFE5ECFD);
    } else {
      assetPath = 'assets/images/broom_stick.png';
      iconBg = const Color(0xFFFFF2D9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => detail(bounty),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Leading chore icon in rounded tinted container
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.cleaning_services,
                      color: primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Chore metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bounty.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Coin token badge
                          Image.asset(
                            'assets/images/coin.png',
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${bounty.points}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5D4017),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Optional reward chip
                          if (bounty.reward.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEBE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🎁',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    bounty.reward,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD35338),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Posted by Roommate',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> detail(Bounty bounty) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final isClaimed = [
          'claimed',
          'active',
          'in_progress',
          'in progress',
        ].contains(bounty.status.toLowerCase());

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bounty.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bounty.description.isEmpty
                      ? 'No extra instructions.'
                      : bounty.description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${bounty.points}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (bounty.reward.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🎁 ${bounty.reward}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!isClaimed)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await widget.bounties.claim(bounty.id);

                        if (!mounted) return;

                        Navigator.pop(sheetContext);
                        await refresh();
                      } catch (error) {
                        if (!sheetContext.mounted) return;

                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(widget.bounties.error(error))),
                        );
                      }
                    },
                    child: const Text(
                      'Claim Bounty',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isClaimed)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await widget.bounties.complete(bounty.id);

                        if (!mounted) return;

                        Navigator.pop(sheetContext);
                        await refresh();
                      } catch (error) {
                        if (!sheetContext.mounted) return;

                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(widget.bounties.error(error))),
                        );
                      }
                    },
                    child: const Text(
                      'Mark Completed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget leaderboard() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0C8),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 70,
                color: Color(0xFFFFB800),
              ),
              SizedBox(height: 8),
              Text(
                'Leaderboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Compete with your roommates and earn points.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget profile() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 18),
        Center(
          child: ClipOval(
            child: Image.asset(
              'assets/images/default_profile.png',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFD6F3E6),
                child: Text(
                  widget.user.name.isEmpty
                      ? '?'
                      : widget.user.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: primaryGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          widget.user.email,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Log out',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class CreateBounty extends StatefulWidget {
  const CreateBounty({super.key, required this.service});

  final BountyService service;

  @override
  State<CreateBounty> createState() => _CreateBountyState();
}

class _CreateBountyState extends State<CreateBounty> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final points = TextEditingController(text: '50');
  final reward = TextEditingController();

  String category = 'Cleaning';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    points.dispose();
    reward.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.service.create({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'reward_value': int.parse(points.text),
        'reward_description': reward.text.trim(),
        'category': category,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = widget.service.error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Bounty')),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Post a bounty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Take out the trash',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: points,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reward points'),
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Enter a positive number of points';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reward,
              decoration: const InputDecoration(
                labelText: 'Reward',
                hintText: 'Free coffee, pizza treat',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  [
                    'Cleaning',
                    'Laundry',
                    'Kitchen',
                    'Groceries',
                    'Maintenance',
                    'Other',
                  ].map((item) {
                    return ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      onSelected: (_) => setState(() => category = item),
                    );
                  }).toList(),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            GreenButton(
              'Post Bounty',
              loading: busy,
              onPressed: busy ? null : submit,
            ),
          ],
        ),
      ),
    );
  }
}
