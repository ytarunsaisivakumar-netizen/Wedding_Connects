/// Sample (fictional) vendor data for the India launch.
///
/// Replace [allVendors] with a call to a real backend later; the screens only
/// use [searchVendors] and [indiaCities].
enum VendorType { hall, caterer }

class Vendor {
  final String id;
  final VendorType type;
  final String name;
  final String city;
  final String area;

  /// Hall: rent per day (INR). Caterer: price per plate (INR).
  final int price;

  /// Hall: max guests it holds. Caterer: max guests it can serve.
  final int capacity;
  final double rating;
  final List<String> tags;

  const Vendor({
    required this.id,
    required this.type,
    required this.name,
    required this.city,
    required this.area,
    required this.price,
    required this.capacity,
    required this.rating,
    required this.tags,
  });
}

/// Cities offered in the picker. Cities without vendors show an empty state.
const List<String> indiaCities = [
  'Ahmedabad',
  'Amritsar',
  'Bengaluru',
  'Bhopal',
  'Chandigarh',
  'Chennai',
  'Coimbatore',
  'Delhi',
  'Goa',
  'Guntur',
  'Hyderabad',
  'Indore',
  'Jaipur',
  'Kochi',
  'Kolkata',
  'Lucknow',
  'Mumbai',
  'Nagpur',
  'Pune',
  'Surat',
  'Tirupati',
  'Vijayawada',
  'Visakhapatnam',
];

Vendor _h(String id, String name, String city, String area, int price,
        int capacity, double rating, List<String> tags) =>
    Vendor(
        id: id,
        type: VendorType.hall,
        name: name,
        city: city,
        area: area,
        price: price,
        capacity: capacity,
        rating: rating,
        tags: tags);

Vendor _c(String id, String name, String city, String area, int price,
        int capacity, double rating, List<String> tags) =>
    Vendor(
        id: id,
        type: VendorType.caterer,
        name: name,
        city: city,
        area: area,
        price: price,
        capacity: capacity,
        rating: rating,
        tags: tags);

final List<Vendor> allVendors = [
  // ---- Hyderabad ----
  _h('h1', 'Royal Orchid Convention', 'Hyderabad', 'Gachibowli', 350000, 1200,
      4.6, ['AC', 'Parking', 'Bridal room']),
  _h('h2', 'Shubh Muhurtham Function Hall', 'Hyderabad', 'Kukatpally', 120000,
      500, 4.2, ['AC', 'Parking']),
  _h('h3', 'Nizam Heritage Lawns', 'Hyderabad', 'Banjara Hills', 600000, 2000,
      4.8, ['Lawn', 'Stage', 'Valet']),
  _c('c1', 'Paradise Feast Caterers', 'Hyderabad', 'Secunderabad', 650, 3000,
      4.7, ['Hyderabadi', 'Non-veg', 'Veg']),
  _c('c2', 'Annapurna Pure Veg Catering', 'Hyderabad', 'Ameerpet', 400, 1500,
      4.4, ['Pure veg', 'South Indian']),
  _c('c3', 'Grand Banquet Kitchens', 'Hyderabad', 'Madhapur', 1100, 2500, 4.5,
      ['Multi-cuisine', 'Live counters']),

  // ---- Bengaluru ----
  _h('h4', 'Palace Grounds Pavilion', 'Bengaluru', 'Jayamahal', 750000, 3000,
      4.7, ['Lawn', 'AC hall', 'Parking']),
  _h('h5', 'Lotus Kalyana Mantapa', 'Bengaluru', 'Jayanagar', 150000, 700,
      4.3, ['AC', 'Dining hall']),
  _h('h6', 'Whitefield Grand Banquets', 'Bengaluru', 'Whitefield', 300000,
      900, 4.5, ['AC', 'Valet', 'Bridal room']),
  _c('c4', 'Udupi Sagar Caterers', 'Bengaluru', 'Malleshwaram', 380, 2000,
      4.5, ['Pure veg', 'South Indian']),
  _c('c5', 'Spice Route Events', 'Bengaluru', 'Indiranagar', 900, 1800, 4.6,
      ['Multi-cuisine', 'Live counters']),
  _c('c6', 'Heritage Thali House', 'Bengaluru', 'Koramangala', 550, 1200, 4.3,
      ['Veg', 'Non-veg']),

  // ---- Mumbai ----
  _h('h7', 'Marine Drive Banquet', 'Mumbai', 'Churchgate', 900000, 800, 4.7,
      ['Sea view', 'AC', 'Valet']),
  _h('h8', 'Andheri Celebration Hall', 'Mumbai', 'Andheri', 250000, 600, 4.1,
      ['AC', 'Parking']),
  _h('h9', 'Juhu Garden Lawns', 'Mumbai', 'Juhu', 700000, 1500, 4.6,
      ['Lawn', 'Stage']),
  _c('c7', 'Mumbai Masala Caterers', 'Mumbai', 'Dadar', 700, 2500, 4.5,
      ['Gujarati', 'Maharashtrian', 'Veg']),
  _c('c8', 'Bandra Fusion Kitchen', 'Mumbai', 'Bandra', 1400, 1200, 4.7,
      ['Multi-cuisine', 'Live counters']),

  // ---- Delhi ----
  _h('h10', 'Chhatarpur Farm Estate', 'Delhi', 'Chhatarpur', 800000, 2500,
      4.6, ['Lawn', 'Parking', 'Bridal suite']),
  _h('h11', 'Karol Bagh Banquet', 'Delhi', 'Karol Bagh', 200000, 600, 4.0,
      ['AC', 'Parking']),
  _h('h12', 'Dwarka Royal Hall', 'Delhi', 'Dwarka', 280000, 1000, 4.4,
      ['AC', 'Stage', 'Parking']),
  _c('c9', 'Punjabi Tadka Caterers', 'Delhi', 'Rajouri Garden', 600, 3000,
      4.5, ['North Indian', 'Veg', 'Non-veg']),
  _c('c10', 'Chandni Chowk Delights', 'Delhi', 'Old Delhi', 450, 2000, 4.3,
      ['Street food', 'Veg']),

  // ---- Chennai ----
  _h('h13', 'Marina Mahal', 'Chennai', 'Adyar', 220000, 800, 4.4,
      ['AC', 'Parking', 'Dining hall']),
  _h('h14', 'ECR Beachside Lawns', 'Chennai', 'ECR', 500000, 1500, 4.6,
      ['Beach', 'Lawn', 'Stage']),
  _c('c11', 'Saravana Wedding Feasts', 'Chennai', 'T. Nagar', 420, 3000, 4.6,
      ['Pure veg', 'South Indian', 'Banana-leaf']),
  _c('c12', 'Chettinad Spice Caterers', 'Chennai', 'Mylapore', 700, 1500,
      4.4, ['Chettinad', 'Non-veg']),

  // ---- Pune ----
  _h('h15', 'Shaniwar Wada Lawns', 'Pune', 'Kothrud', 260000, 1200, 4.4,
      ['Lawn', 'Parking']),
  _h('h16', 'Koregaon Park Banquet', 'Pune', 'Koregaon Park', 380000, 700,
      4.6, ['AC', 'Valet']),
  _c('c13', 'Peshwai Catering Co.', 'Pune', 'Deccan', 480, 2500, 4.5,
      ['Maharashtrian', 'Veg']),
  _c('c14', 'Aundh Gourmet Events', 'Pune', 'Aundh', 850, 1500, 4.3,
      ['Multi-cuisine', 'Live counters']),

  // ---- Kolkata ----
  _h('h17', 'Salt Lake Celebration Centre', 'Kolkata', 'Salt Lake', 240000,
      900, 4.3, ['AC', 'Parking']),
  _h('h18', 'Victoria Heritage Hall', 'Kolkata', 'Park Street', 450000, 600,
      4.7, ['Heritage', 'AC']),
  _c('c15', 'Bhoj Bengali Caterers', 'Kolkata', 'Ballygunge', 520, 2000, 4.6,
      ['Bengali', 'Fish', 'Veg']),
  _c('c16', 'Kolkata Royal Kitchen', 'Kolkata', 'New Town', 750, 1800, 4.4,
      ['Mughlai', 'Multi-cuisine']),

  // ---- Jaipur ----
  _h('h19', 'Amer Fort Palace Lawns', 'Jaipur', 'Amer Road', 900000, 2500,
      4.8, ['Palace', 'Lawn', 'Stage']),
  _h('h20', 'Pink City Banquet', 'Jaipur', 'Vaishali Nagar', 180000, 800,
      4.2, ['AC', 'Parking']),
  _c('c17', 'Rajasthani Thaal Caterers', 'Jaipur', 'C-Scheme', 600, 3000,
      4.6, ['Rajasthani', 'Veg']),

  // ---- Ahmedabad ----
  _h('h21', 'Sabarmati Riverfront Hall', 'Ahmedabad', 'Riverfront', 260000,
      1100, 4.4, ['AC', 'Parking']),
  _c('c18', 'Gujarati Rasoi Caterers', 'Ahmedabad', 'Navrangpura', 450, 3500,
      4.5, ['Gujarati', 'Pure veg', 'Jain']),

  // ---- Kochi ----
  _h('h22', 'Backwater Convention', 'Kochi', 'Edappally', 200000, 700, 4.3,
      ['AC', 'Parking']),
  _c('c19', 'Malabar Sadya Caterers', 'Kochi', 'Ernakulam', 500, 2000, 4.6,
      ['Kerala', 'Sadya', 'Veg', 'Non-veg']),

  // ---- Vijayawada / Guntur / Visakhapatnam / Tirupati ----
  _h('h23', 'Krishna Kalyana Vedika', 'Vijayawada', 'Benz Circle', 90000, 600,
      4.2, ['AC', 'Parking']),
  _h('h24', 'Amaravati Grand Convention', 'Vijayawada', 'Gunadala', 260000,
      1500, 4.5, ['AC', 'Stage', 'Parking']),
  _c('c20', 'Andhra Ruchulu Caterers', 'Vijayawada', 'Labbipet', 380, 3000,
      4.6, ['Andhra', 'Non-veg', 'Veg']),
  _h('h25', 'Guntur Spice Convention', 'Guntur', 'Brodipet', 100000, 800, 4.1,
      ['AC', 'Parking']),
  _c('c21', 'Guntur Kaaram Catering', 'Guntur', 'Arundelpet', 350, 2500, 4.4,
      ['Andhra', 'Non-veg']),
  _h('h26', 'Vizag Bay View Hall', 'Visakhapatnam', 'Beach Road', 320000, 900,
      4.6, ['Sea view', 'AC']),
  _c('c22', 'Vizag Coastal Caterers', 'Visakhapatnam', 'MVP Colony', 480, 2000,
      4.4, ['Seafood', 'Andhra', 'Veg']),
  _h('h27', 'Sri Venkateswara Kalyana Mandapam', 'Tirupati', 'Alipiri Road',
      80000, 700, 4.5, ['Traditional', 'Parking']),
  _c('c23', 'Tirumala Prasadam Caterers', 'Tirupati', 'Tiruchanur', 300,
      2500, 4.7, ['Pure veg', 'South Indian']),
];

/// Vendors of [type] in [city], optionally limited by price range and guests.
List<Vendor> searchVendors({
  required VendorType type,
  required String city,
  int? minPrice,
  int? maxPrice,
  int? guests,
  String? area,
}) {
  return allVendors.where((v) {
    if (v.type != type) return false;
    if (v.city.toLowerCase() != city.toLowerCase()) return false;
    if (area != null && v.area != area) return false;
    if (minPrice != null && v.price < minPrice) return false;
    if (maxPrice != null && v.price > maxPrice) return false;
    if (guests != null && v.capacity < guests) return false;
    return true;
  }).toList();
}

String formatInr(int amount) {
  final s = amount.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}
