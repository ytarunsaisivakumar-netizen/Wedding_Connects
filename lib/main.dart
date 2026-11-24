import 'package:flutter/material.dart';

import 'auth/auth_screens.dart';
import 'auth/auth_service.dart';
import 'booking_screens.dart';
import 'booking_service.dart';
import 'data/vendors.dart';
import 'favorites_service.dart';
import 'location_service.dart';
import 'theme.dart';
import 'vendor_account_service.dart';
import 'vendor_dashboard.dart';
import 'vendor_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authService.init();
  await locationService.init();
  await favoritesService.init();
  await vendorAccounts.init();
  await bookingService.init();
  runApp(const WeddingConnectsApp());
}

class WeddingConnectsApp extends StatelessWidget {
  const WeddingConnectsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WC TEST',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: maroon),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: maroon,
        ),
      ),
      home: ListenableBuilder(
        listenable: authService,
        builder: (context, _) => authService.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int get selectedIndex => homeTab.value;

  @override
  void initState() {
    super.initState();
    homeTab.value = 0; // start on Home after every login
    homeTab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    homeTab.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeContent(),
      const SavedPage(),
      const BookingsPage(),
      ListenableBuilder(
        listenable: authService,
        builder: (context, _) => ProfilePage(
          onOpenFavorites: () => homeTab.value = 1,
          onOpenBookings: () => homeTab.value = 2,
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: lightPink,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => homeTab.value = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.favorite,
                color: maroon,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wedding Connects',
                    style: TextStyle(
                      color: maroon,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Make your special day memorable',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications will be available soon.'),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                color: maroon,
                size: 27,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Location selector
        const Text(
          'YOUR LOCATION',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 9),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showCityPicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFE1E3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: maroon),
                const SizedBox(width: 12),
                Expanded(
                  child: ListenableBuilder(
                    listenable: locationService,
                    builder: (_, _) => Text(
                      locationService.city == null
                          ? 'Choose your city'
                          : '${locationService.city}, India',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: maroon),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Welcome section
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: maroon,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan your',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Perfect Wedding Day',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Discover function halls and catering services in one place.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Color(0xFFFFDCE5),
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Your celebration starts here',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'What are you looking for?',
          style: TextStyle(
            color: maroon,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Choose a service to get started.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 18),

        ServiceCard(
          title: 'Function Halls',
          subtitle: 'Find a venue for your special day',
          icon: Icons.account_balance,
          type: VendorType.hall,
        ),

        const SizedBox(height: 16),

        ServiceCard(
          title: 'Catering Services',
          subtitle: 'Explore menus and meal packages',
          icon: Icons.restaurant_menu,
          type: VendorType.caterer,
        ),

        const SizedBox(height: 24),

        const Row(
          children: [
            Icon(Icons.verified_outlined, color: maroon, size: 21),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Find the right services for your celebration.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VendorType type;

  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shadowColor: maroon.withAlpha(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF0E3E5)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorListScreen(type: type),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: maroon, size: 34),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Explore services',
                      style: TextStyle(
                        color: maroon,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: maroon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceDetailsScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> details;

  const ServiceDetailsScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: maroon,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 54),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore options for your special day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'What you can do',
            style: TextStyle(
              color: maroon,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: maroon,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      detail,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This is the initial app layout. Real vendor listings, photos, prices, date availability and booking requests will be added in the next development steps.',
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenBookings;

  const ProfilePage({
    super.key,
    required this.onOpenFavorites,
    required this.onOpenBookings,
  });

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send feedback'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell us what you think...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogContext);
              if (text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authService.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _option(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? Colors.red.shade700 : maroon;
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: danger ? Colors.red.shade50 : lightPink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: danger ? color : Colors.black87,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 15, color: color),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            color: maroon,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: maroon,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: lightPink,
                child: Icon(Icons.person, color: maroon, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.phone != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.phone!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (user.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 1,
          shadowColor: maroon.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF0E3E5)),
          ),
          child: Column(
            children: [
              _option(
                Icons.edit_outlined,
                'Edit profile',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _option(Icons.favorite_border, 'Favorites', onOpenFavorites),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _option(Icons.calendar_month_outlined, 'Your Bookings',
                  onOpenBookings),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListenableBuilder(
                listenable: Listenable.merge([vendorAccounts, bookingService]),
                builder: (context, _) {
                  final pending = bookingService
                      .pendingCountFor(vendorAccounts.myVendorIds);
                  return _option(
                    Icons.storefront_outlined,
                    vendorAccounts.isVendor
                        ? (pending > 0
                            ? 'Vendor dashboard ($pending pending)'
                            : 'Vendor dashboard')
                        : 'Are you a vendor? List your business',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VendorDashboardScreen()),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _option(Icons.feedback_outlined, 'Send feedback',
                  () => _showFeedbackDialog(context)),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _option(Icons.logout, 'Logout', () => _confirmLogout(context),
                  danger: true),
            ],
          ),
        ),
      ],
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const SimplePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: maroon, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: maroon,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
