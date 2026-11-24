import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'booking_service.dart';
import 'data/vendors.dart';
import 'theme.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

const _hallOccasions = ['Wedding', 'Reception', 'Engagement', 'Other function'];
const _mealOptions = ['Lunch', 'Dinner', 'Breakfast', 'High tea'];

/// Form to request a hall booking or a catering enquiry for a chosen date.
class BookingRequestScreen extends StatefulWidget {
  final Vendor vendor;
  const BookingRequestScreen({super.key, required this.vendor});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _guests = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  late String _occasion;
  bool _submitting = false;

  bool get _isHall => widget.vendor.type == VendorType.hall;

  @override
  void initState() {
    super.initState();
    final user = authService.currentUser;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _occasion = _isHall ? _hallOccasions.first : _mealOptions.first;
    _guests.addListener(() => setState(() {})); // refresh the estimate
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _guests.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _firstDate => dateOnly(DateTime.now()).add(const Duration(days: 1));

  Future<void> _pickDate() async {
    final first = _firstDate;
    final last = first.add(const Duration(days: 730));
    // Start on the first date that can actually be selected.
    DateTime? initial = _date;
    if (initial == null) {
      for (var i = 0; i < 60; i++) {
        final d = first.add(Duration(days: i));
        if (bookingService.isDateAvailable(widget.vendor, d)) {
          initial = d;
          break;
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? first,
      firstDate: first,
      lastDate: last,
      helpText: 'Select event date',
      selectableDayPredicate: (d) =>
          bookingService.isDateAvailable(widget.vendor, d),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  int? get _guestCount => int.tryParse(_guests.text.trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final err = await bookingService.submit(
      vendor: widget.vendor,
      date: _date!,
      guests: _guestCount!,
      occasion: _occasion,
      contactName: _name.text,
      contactPhone: _phone.text,
      notes: _notes.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err != null) {
      setState(() => _date = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final viewBookings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: maroon, size: 44),
        title: Text(_isHall ? 'Booking request sent' : 'Enquiry sent'),
        content: Text(
          '${widget.vendor.name} — ${formatDate(_date!)}.\n\n'
          'Your request is pending. You can track or cancel it in the Bookings tab.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Done'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: maroon),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('View bookings'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (viewBookings == true) {
      homeTab.value = 2;
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      // Back to wherever the user started (the list or the Saved tab).
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final guests = _guestCount;
    final estimate =
        (guests != null && guests > 0) ? estimateCost(v, guests) : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isHall ? 'Request booking' : 'Catering enquiry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _vendorSummary(v),
            const SizedBox(height: 22),

            // Date
            FormField<DateTime>(
              validator: (_) =>
                  _date == null ? 'Select an event date' : null,
              builder: (state) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await _pickDate();
                  state.didChange(_date);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Event date',
                    helperText: 'Greyed-out dates are not available.',
                    errorText: state.errorText,
                    prefixIcon:
                        const Icon(Icons.calendar_month, color: maroon),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _date == null ? 'Tap to choose a date' : formatDate(_date!),
                    style: TextStyle(
                        color: _date == null ? Colors.black45 : Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _occasion,
              decoration: InputDecoration(
                labelText: _isHall ? 'Function type' : 'Meal',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                for (final o in (_isHall ? _hallOccasions : _mealOptions))
                  DropdownMenuItem(value: o, child: Text(o)),
              ],
              onChanged: (o) => setState(() => _occasion = o ?? _occasion),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _guests,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of guests',
                helperText: _isHall
                    ? 'This hall holds up to ${v.capacity} guests.'
                    : 'Serves up to ${v.capacity} guests.',
                prefixIcon: const Icon(Icons.groups_outlined, color: maroon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (t) {
                final n = int.tryParse((t ?? '').trim());
                if (n == null || n < 1) return 'Enter the number of guests';
                if (n > v.capacity) {
                  return 'Maximum is ${v.capacity} guests for this vendor';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (estimate != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.receipt_long_outlined, color: maroon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isHall
                          ? 'Estimated hall rent: ${formatInr(estimate)}'
                          : 'Estimated: ${formatInr(estimate)} '
                              '(${formatInr(v.price)} × $guests plates)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),

            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Your name',
                prefixIcon: const Icon(Icons.person_outline, color: maroon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (t) => (t ?? '').trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact mobile number',
                helperText: 'The vendor will use this to reach you.',
                prefixIcon: const Icon(Icons.phone_outlined, color: maroon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (t) =>
                  AuthService.validateContact(ContactType.phone, t),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes for the vendor (optional)',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: maroon),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(_isHall ? 'Send booking request' : 'Send enquiry'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This is a request, not a confirmed booking. The vendor will confirm or decline it. No payment is taken.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vendorSummary(Vendor v) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E3E5)),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: lightPink, borderRadius: BorderRadius.circular(12)),
            child: Icon(_isHall ? Icons.account_balance : Icons.restaurant_menu,
                color: maroon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: maroon)),
                const SizedBox(height: 2),
                Text('${v.area}, ${v.city}',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _isHall
                      ? '${formatInr(v.price)} / day'
                      : '${formatInr(v.price)} / plate',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ]),
      );
}

/// The Bookings tab: the current user's requests.
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bookingService,
      builder: (context, _) {
        final all = bookingService.bookings;
        final active = all.where((b) => b.isActive).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final past = all.where((b) => !b.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text('My Bookings',
                style: TextStyle(
                    color: maroon, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Column(children: [
                  Icon(Icons.calendar_month_outlined, color: maroon, size: 48),
                  SizedBox(height: 14),
                  Text(
                    'No booking requests yet.\nOpen a function hall or caterer and send a request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ]),
              ),
            if (active.isNotEmpty) ...[
              _header('Upcoming (${active.length})'),
              for (final b in active) _BookingCard(booking: b),
            ],
            if (past.isNotEmpty) ...[
              _header('Declined / cancelled (${past.length})'),
              for (final b in past) _BookingCard(booking: b),
            ],
          ],
        );
      },
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      );
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  (String, Color, Color) get _statusStyle => switch (booking.status) {
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
            'Cancelled',
            Colors.black54,
            const Color(0xFFEDEDED)
          ),
      };

  Future<void> _confirmCancel(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(booking.status == BookingStatus.confirmed
            ? 'Cancel this booking?'
            : 'Cancel this request?'),
        content: Text('Your ${booking.status == BookingStatus.confirmed ? 'confirmed booking' : 'request'} '
            'with $name for ${formatDate(booking.date)} will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: maroon),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (ok == true) await bookingService.cancel(booking.id);
  }

  @override
  Widget build(BuildContext context) {
    final vendor =
        allVendors.where((v) => v.id == booking.vendorId).firstOrNull;
    final isHall = vendor?.type == VendorType.hall;
    final (label, fg, bg) = _statusStyle;
    final name = vendor?.name ?? 'Vendor no longer listed';
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
              Icon(isHall ? Icons.account_balance : Icons.restaurant_menu,
                  color: maroon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
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
            if (vendor != null) ...[
              const SizedBox(height: 4),
              Text('${vendor.area}, ${vendor.city}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            _row(Icons.calendar_month_outlined, formatDate(booking.date)),
            _row(Icons.celebration_outlined, booking.occasion),
            _row(Icons.groups_outlined, '${booking.guests} guests'),
            _row(Icons.currency_rupee,
                'Estimate ${formatInr(booking.estimate)}'),
            if (booking.notes.isNotEmpty)
              _row(Icons.notes_outlined, booking.notes),
            if (booking.status == BookingStatus.pending)
              _row(Icons.hourglass_empty,
                  'Waiting for the vendor to respond.'),
            if (booking.response.isNotEmpty)
              _row(Icons.reply_outlined, 'Vendor: ${booking.response}'),
            if (booking.status == BookingStatus.confirmed)
              _row(Icons.check_circle_outline,
                  'The vendor has confirmed this date.'),
            if (booking.isActive) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _confirmCancel(context, name),
                  child: Text(
                      booking.status == BookingStatus.confirmed
                          ? 'Cancel booking'
                          : 'Cancel request',
                      style: TextStyle(color: Colors.red.shade700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
