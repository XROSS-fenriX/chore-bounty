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
      // The FutureBuilder displays API errors.
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
    const titles = ['Home', 'My Tasks', 'Leaderboard', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        actions: [
          if (tab == 3)
            IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
            ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [home(), tasks(), leaderboard(), profile()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF159653),
        foregroundColor: Colors.white,
        onPressed: create,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) {
          setState(() => tab = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget home() {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFDCA5),
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : 'C',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Good day,', style: TextStyle(fontSize: 12)),
                    Text(
                      widget.user.name.split(' ').first,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refresh,
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF169653), Color(0xFF087548)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep your space tidy!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Complete bounties and earn rewards.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.card_giftcard, size: 50, color: Color(0xFFFFD15C)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['All', 'Available', 'My Tasks'].map((item) {
              final selected = filter == item;

              return ChoiceChip(
                label: Text(item),
                selected: selected,
                selectedColor: const Color(0xFF169653),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                ),
                onSelected: (_) {
                  setState(() => filter = item);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bounties for you',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          bountyList(filter),
        ],
      ),
    );
  }

  Widget tasks() {
    return RefreshIndicator(
      onRefresh: refresh,
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
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
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
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No bounties found yet. Tap + to create one.'),
            ),
          );
        }

        return Column(
          children: items.map((bounty) {
            return BountyTile(bounty: bounty, onTap: () => detail(bounty));
          }).toList(),
        );
      },
    );
  }

  Future<void> detail(Bounty bounty) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isClaimed = [
          'claimed',
          'active',
          'in_progress',
          'in progress',
        ].contains(bounty.status.toLowerCase());

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bounty.title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bounty.description.isEmpty
                      ? 'No extra instructions.'
                      : bounty.description,
                ),
                const SizedBox(height: 10),
                Text('🪙 ${bounty.points} points  ${bounty.reward}'),
                const SizedBox(height: 20),
                if (!isClaimed)
                  FilledButton(
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
                    child: const Text('Claim Bounty'),
                  ),
                if (isClaimed)
                  FilledButton(
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
                    child: const Text('Mark Completed'),
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
                size: 80,
                color: Color(0xFFFFB800),
              ),
              Text(
                'Leaderboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              Text(
                'Compete with your roommates and earn points.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Connect a GET /api/leaderboard endpoint '
              'to display real household rankings.',
            ),
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
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFB9ECE6),
          child: Text(
            widget.user.name.isEmpty ? '?' : widget.user.name[0].toUpperCase(),
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        Text(widget.user.email, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Card(
          child: ListTile(
            leading: Icon(Icons.home_work_outlined),
            title: Text('Household'),
            subtitle: Text(
              'Household details will appear when provided by the API.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
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
