import 'package:flutter/material.dart';

import 'booking_screens.dart' show formatDate;
import 'booking_service.dart';
import 'data/vendors.dart';
import 'theme.dart';
import 'vendor_account_service.dart';

enum _Tab { pending, confirmed, closed }

/// For business owners: manage listings and answer booking requests.
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  _Tab _tab = _Tab.pending;

  Future<void> _claim() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClaimListingScreen()),
    );
  }

  Future<void> _release(Vendor v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Stop managing this listing?'),
        content: Text(
            '${v.name} will no longer be linked to your account, and you will stop seeing its requests. Existing requests stay as they are.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: maroon),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await vendorAccounts.release(v.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor dashboard')),
      body: ListenableBuilder(
        listenable: Listenable.merge([vendorAccounts, bookingService]),
        builder: (context, _) {
          final mine = vendorAccounts.myVendors;
          if (mine.isEmpty) return _empty();
          final ids = vendorAccounts.myVendorIds;
          final all = bookingService.requestsFor(ids);
          final pending =
              all.where((b) => b.status == BookingStatus.pending).toList();
          final confirmed =
              all.where((b) => b.status == BookingStatus.confirmed).toList();
          final closed = all
              .where((b) =>
                  b.status == BookingStatus.declined ||
                  b.status == BookingStatus.cancelled)
              .toList();
          final shown = switch (_tab) {
            _Tab.pending => pending,
            _Tab.confirmed => confirmed,
            _Tab.closed => closed,
          }
            ..sort((a, b) => a.date.compareTo(b.date));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _header('Your listings'),
              for (final v in mine) _listingTile(v),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _claim,
                  icon: const Icon(Icons.add, color: maroon),
                  label: const Text('Claim another listing',
                      style: TextStyle(color: maroon)),
                ),
              ),
              const SizedBox(height: 8),
              _header('Booking requests'),
              SegmentedButton<_Tab>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: _Tab.pending,
                      label: Text('Pending (${pending.length})')),
                  ButtonSegment(
                      value: _Tab.confirmed,
                      label: Text('Confirmed (${confirmed.length})')),
                  ButtonSegment(
                      value: _Tab.closed,
                      label: Text('Closed (${closed.length})')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 14),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Text(
                    switch (_tab) {
                      _Tab.pending => 'No pending requests right now.',
                      _Tab.confirmed => 'No confirmed bookings yet.',
                      _Tab.closed => 'No declined or cancelled requests.',
                    },
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              for (final b in shown)
                _RequestCard(booking: b, showListing: mine.length > 1),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.storefront_outlined, color: maroon, size: 52),
            const SizedBox(height: 14),
            const Text('Manage your business',
                style: TextStyle(
                    color: maroon, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Claim your function hall or catering listing to receive booking requests and confirm or decline them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: maroon),
              onPressed: _claim,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Claim a listing'),
            ),
          ]),
        ),
      );

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      );

  Widget _listingTile(Vendor v) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF0E3E5)),
        ),
        child: ListTile(
          leading: Icon(
              v.type == VendorType.hall
                  ? Icons.account_balance
                  : Icons.restaurant_menu,
              color: maroon),
          title: Text(v.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: maroon)),
          subtitle: Text('${v.area}, ${v.city}'),
          trailing: IconButton(
            tooltip: 'Stop managing',
            icon: const Icon(Icons.link_off, size: 20),
            onPressed: () => _release(v),
          ),
        ),
      );
}

class _RequestCard extends StatefulWidget {
  final Booking booking;
  final bool showListing;
  const _RequestCard({required this.booking, required this.showListing});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    final b = widget.booking;
    final note = await showDialog<String>(
      context: context,
      builder: (d) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(accept ? 'Confirm this request?' : 'Decline this request?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${b.contactName} · ${formatDate(b.date)} · ${b.guests} guests'),
              if (accept)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Other pending requests for this date will be declined automatically.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: accept
                      ? 'Message to customer (optional)'
                      : 'Reason (optional)',
                  hintText: accept
                      ? 'e.g. Advance details, arrival time'
                      : 'e.g. Already booked, outside our capacity',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d),
                child: const Text('Back')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: accept ? maroon : Colors.red.shade700),
              onPressed: () => Navigator.pop(d, c.text),
              child: Text(accept ? 'Confirm' : 'Decline'),
            ),
          ],
        );
      },
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    final err = await bookingService.respond(
        bookingId: b.id, accept: accept, note: note);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ??
          (accept ? 'Booking confirmed.' : 'Request declined.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final vendor = allVendors.where((v) => v.id == b.vendorId).firstOrNull;
    final (label, fg, bg) = switch (b.status) {
      BookingStatus.pending => (
          'Pending',
          const Color(0xFF8A5A00),
          const Color(0xFFFFF0CC)
        ),
      BookingStatus.confirmed => (
          'Confirmed',
          const Color(0xFF1B6B35),
          const Color(0xFFDDF3E4)
        ),
      BookingStatus.declined => (
          'Declined',
          Colors.red.shade800,
          Colors.red.shade50
        ),
      BookingStatus.cancelled => (
          'Cancelled by customer',
          Colors.black54,
          const Color(0xFFEDEDED)
        ),
    };
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0E3E5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(formatDate(b.date),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: maroon)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(label,
                    style: TextStyle(
                        color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
            if (widget.showListing && vendor != null) ...[
              const SizedBox(height: 4),
              Text(vendor.name,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            _row(Icons.person_outline, b.contactName),
            _row(Icons.phone_outlined, b.contactPhone, selectable: true),
            _row(Icons.celebration_outlined, b.occasion),
            _row(Icons.groups_outlined, '${b.guests} guests'),
            _row(Icons.currency_rupee, 'Estimate ${formatInr(b.estimate)}'),
            if (b.notes.isNotEmpty) _row(Icons.notes_outlined, b.notes),
            if (b.response.isNotEmpty)
              _row(Icons.reply_outlined, 'Your reply: ${b.response}'),
            _row(Icons.schedule, 'Requested ${formatDate(b.createdAt)}'),
            if (b.status == BookingStatus.pending) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                    onPressed: _busy ? null : () => _respond(false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: maroon),
                    onPressed: _busy ? null : () => _respond(true),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Confirm'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool selectable = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: selectable ? SelectableText(text) : Text(text)),
        ]),
      );
}

/// Pick a listing to manage.
class ClaimListingScreen extends StatefulWidget {
  const ClaimListingScreen({super.key});

  @override
  State<ClaimListingScreen> createState() => _ClaimListingScreenState();
}

class _ClaimListingScreenState extends State<ClaimListingScreen> {
  String _q = '';

  Future<void> _claim(Vendor v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Claim this listing?'),
        content: Text(
            'You will manage ${v.name} (${v.area}, ${v.city}) and receive its booking requests.\n\nDemo only: a live app would verify that you own this business first.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: maroon),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await vendorAccounts.claim(v.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = allVendors
        .where((v) => !vendorAccounts.isClaimed(v.id))
        .where((v) =>
            q.isEmpty ||
            v.name.toLowerCase().contains(q) ||
            v.city.toLowerCase().contains(q) ||
            v.area.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.city.compareTo(b.city));
    return Scaffold(
      appBar: AppBar(title: const Text('Claim your listing')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search by business name or city',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('No unclaimed listings match.',
                      style: TextStyle(color: Colors.black54)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final v = list[i];
                    return ListTile(
                      leading: Icon(
                          v.type == VendorType.hall
                              ? Icons.account_balance
                              : Icons.restaurant_menu,
                          color: maroon),
                      title: Text(v.name),
                      subtitle: Text(
                          '${v.type == VendorType.hall ? 'Function hall' : 'Caterer'} · ${v.area}, ${v.city}'),
                      onTap: () => _claim(v),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
