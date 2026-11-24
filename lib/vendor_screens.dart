import 'package:flutter/material.dart';

import 'booking_screens.dart';
import 'data/vendors.dart';
import 'favorites_service.dart';
import 'location_service.dart';
import 'theme.dart';

/// Searchable list of Indian cities. Returns the chosen city.
Future<void> showCityPicker(BuildContext context) async {
  final picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _CityPickerSheet(),
  );
  if (picked != null) await locationService.setCity(picked);
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final cities =
        indiaCities.where((c) => c.toLowerCase().contains(q)).toList();
    final height = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Choose your city',
                style: TextStyle(
                    color: maroon, fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Country: India',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search city',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            Expanded(
              child: cities.isEmpty
                  ? const Center(child: Text('No matching city'))
                  : ListView.builder(
                      itemCount: cities.length,
                      itemBuilder: (_, i) {
                        final c = cities[i];
                        final selected = c == locationService.city;
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined,
                              color: maroon),
                          title: Text(c),
                          trailing: selected
                              ? const Icon(Icons.check, color: maroon)
                              : null,
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Function halls or catering services in the selected city, with filters.
class VendorListScreen extends StatefulWidget {
  final VendorType type;
  const VendorListScreen({super.key, required this.type});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

enum _Sort { ratingDesc, priceAsc, priceDesc }

class _VendorListScreenState extends State<VendorListScreen> {
  late RangeValues _budget;
  int? _guests;
  String? _area;
  String? _areaCity; // city the selected area belongs to
  _Sort _sort = _Sort.ratingDesc;

  bool get _isHall => widget.type == VendorType.hall;

  // Slider bounds and step per vendor type (INR).
  int get _min => _isHall ? 0 : 0;
  int get _max => _isHall ? 1000000 : 2000;
  int get _step => _isHall ? 25000 : 50;

  @override
  void initState() {
    super.initState();
    _budget = RangeValues(_min.toDouble(), _max.toDouble());
  }

  bool get _budgetActive =>
      _budget.start > _min || _budget.end < _max;

  @override
  Widget build(BuildContext context) {
    final title = _isHall ? 'Function Halls' : 'Catering Services';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: locationService,
        builder: (context, _) {
          final city = locationService.city;
          // A neighbourhood only makes sense within its own city.
          if (_areaCity != city) {
            _area = null;
            _areaCity = city;
          }
          return Column(
            children: [
              _cityBar(context, city),
              if (city == null)
                Expanded(child: _noCity(context))
              else ...[
                _filters(context, city),
                Expanded(child: _results(city)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _cityBar(BuildContext context, String? city) {
    return InkWell(
      onTap: () => showCityPicker(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFE1E3)),
        ),
        child: Row(children: [
          const Icon(Icons.location_on_outlined, color: maroon),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  city == null ? 'Choose your city' : '$city, India',
                  style: const TextStyle(fontSize: 15))),
          const Text('Change',
              style: TextStyle(color: maroon, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _noCity(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_city, color: maroon, size: 48),
          const SizedBox(height: 14),
          const Text('Pick a city to see what is available there.',
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: maroon),
            onPressed: () => showCityPicker(context),
            child: const Text('Choose city'),
          ),
        ]),
      ),
    );
  }

  Widget _filters(BuildContext context, String city) {
    final areas = searchVendors(type: widget.type, city: city)
        .map((v) => v.area)
        .toSet()
        .toList()
      ..sort();
    final unit = _isHall ? 'per day' : 'per plate';
    final label = _budgetActive
        ? '${formatInr(_budget.start.round())} – ${_budget.end.round() >= _max ? '${formatInr(_max)}+' : formatInr(_budget.end.round())} $unit'
        : 'Any budget ($unit)';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (areas.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              key: ValueKey('area-$city'),
              initialValue: _area,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Neighbourhood in $city',
                prefixIcon: const Icon(Icons.place_outlined, color: maroon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All neighbourhoods')),
                for (final a in areas)
                  DropdownMenuItem<String?>(value: a, child: Text(a)),
              ],
              onChanged: (v) => setState(() => _area = v),
            ),
            const SizedBox(height: 12),
          ],
          Row(children: [
            const Icon(Icons.currency_rupee, size: 16, color: maroon),
            const SizedBox(width: 4),
            Expanded(
                child: Text('Budget: $label',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          RangeSlider(
            values: _budget,
            min: _min.toDouble(),
            max: _max.toDouble(),
            divisions: (_max - _min) ~/ _step,
            activeColor: maroon,
            onChanged: (v) => setState(() => _budget = v),
          ),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _guests,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Guests',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Any')),
                  DropdownMenuItem(value: 100, child: Text('100+')),
                  DropdownMenuItem(value: 300, child: Text('300+')),
                  DropdownMenuItem(value: 500, child: Text('500+')),
                  DropdownMenuItem(value: 1000, child: Text('1000+')),
                  DropdownMenuItem(value: 2000, child: Text('2000+')),
                ],
                onChanged: (v) => setState(() => _guests = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<_Sort>(
                initialValue: _sort,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Sort by',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: _Sort.ratingDesc, child: Text('Top rated')),
                  DropdownMenuItem(
                      value: _Sort.priceAsc, child: Text('Price: low')),
                  DropdownMenuItem(
                      value: _Sort.priceDesc, child: Text('Price: high')),
                ],
                onChanged: (v) => setState(() => _sort = v ?? _sort),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _results(String city) {
    final list = searchVendors(
      type: widget.type,
      city: city,
      area: _area,
      minPrice: _budget.start > _min ? _budget.start.round() : null,
      maxPrice: _budget.end < _max ? _budget.end.round() : null,
      guests: _guests,
    );
    switch (_sort) {
      case _Sort.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _Sort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
    }

    final kind = _isHall ? 'function halls' : 'caterers';
    if (list.isEmpty) {
      final anyInCity = searchVendors(type: widget.type, city: city).isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            anyInCity
                ? 'No $kind in ${_area ?? city} match your filters. Try another neighbourhood or widen the budget or guest count.'
                : 'No $kind listed in $city yet. Try another city.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${list.length} $kind in $city',
                style: const TextStyle(color: Colors.black54)),
          );
        }
        return VendorCard(vendor: list[i - 1]);
      },
    );
  }
}

/// The Saved tab: every vendor the current user has hearted.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesService,
      builder: (context, _) {
        final saved =
            allVendors.where((v) => favoritesService.isSaved(v.id)).toList();
        final halls = saved.where((v) => v.type == VendorType.hall).toList();
        final caterers =
            saved.where((v) => v.type == VendorType.caterer).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text('Saved',
                style: TextStyle(
                    color: maroon, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (saved.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Column(children: [
                  Icon(Icons.favorite_border, color: maroon, size: 48),
                  SizedBox(height: 14),
                  Text(
                    'Nothing saved yet.\nTap the heart on any function hall or caterer to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ]),
              ),
            if (halls.isNotEmpty) ...[
              _header('Function Halls (${halls.length})'),
              for (final v in halls) VendorCard(vendor: v),
            ],
            if (caterers.isNotEmpty) ...[
              _header('Catering Services (${caterers.length})'),
              for (final v in caterers) VendorCard(vendor: v),
            ],
          ],
        );
      },
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      );
}

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  const VendorCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final isHall = vendor.type == VendorType.hall;
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: lightPink, borderRadius: BorderRadius.circular(12)),
                child: Icon(isHall ? Icons.account_balance : Icons.restaurant_menu,
                    color: maroon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: maroon)),
                    const SizedBox(height: 2),
                    Text('${vendor.area}, ${vendor.city}',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 2),
              Text(vendor.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ListenableBuilder(
                listenable: favoritesService,
                builder: (context, _) {
                  final saved = favoritesService.isSaved(vendor.id);
                  return IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                        color: maroon),
                    onPressed: () {
                      favoritesService.toggle(vendor.id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(saved
                              ? 'Removed from Saved'
                              : 'Saved ${vendor.name}'),
                        ));
                    },
                  );
                },
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text(
                isHall
                    ? '${formatInr(vendor.price)} / day'
                    : '${formatInr(vendor.price)} / plate',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.groups_outlined, size: 18, color: Colors.black54),
              const SizedBox(width: 4),
              Text(isHall
                  ? 'Up to ${vendor.capacity} guests'
                  : 'Serves up to ${vendor.capacity}'),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in vendor.tags)
                  Chip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    backgroundColor: lightPink,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: maroon),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookingRequestScreen(vendor: vendor)),
                ),
                child: Text(isHall ? 'Request booking' : 'Send enquiry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
