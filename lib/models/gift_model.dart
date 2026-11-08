enum GiftCategory { hot, lucky, luxury, intimacy }

class GiftItem {
  final String id;
  final String name;
  final int price; // በኮይን የሚከፈል
  final String icon; // ኢሞጂ ወይም የምስል መንገድ
  final GiftCategory category;

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.category,
  });

  // Lucky ስጦታ ከሆነ 4% (0.04)፤ ሌሎች (Hot, Luxury, Intimacy) ከሆኑ 70% (0.70)
  double get diamondRate => category == GiftCategory.lucky ? 0.04 : 0.70;

  // ሆስቱ የሚያገኘው ዳይመንድ መጠን
  int get calculatedDiamonds => (price * diamondRate).round();

  // የጋምብል ስጦታ መሆኑን መለያ
  bool get isLucky => category == GiftCategory.lucky;
}

class GiftData {
  static const List<GiftItem> allGifts = [
    // --- 1. Hot ምድብ (70% ዳይመንድ) ---
    GiftItem(id: "h1", name: "Rose", price: 10, icon: "🌹", category: GiftCategory.hot),
    GiftItem(id: "h2", name: "Heart", price: 100, icon: "💖", category: GiftCategory.hot),
    GiftItem(id: "h3", name: "Perfume", price: 500, icon: "🧴", category: GiftCategory.hot),
    GiftItem(id: "h4", name: "Diamond Ring", price: 1000, icon: "💍", category: GiftCategory.hot),

    // --- 2. Lucky ምድብ (4% ዳይመንድ + ላኪው ሲፈነዳለት የሚያገኘው) ---
    GiftItem(id: "l1", name: "Lucky Dice", price: 10, icon: "🎲", category: GiftCategory.lucky),
    GiftItem(id: "l2", name: "Lucky Box", price: 100, icon: "🎁", category: GiftCategory.lucky),
    GiftItem(id: "l3", name: "Lucky Wheel", price: 1000, icon: "🎡", category: GiftCategory.lucky),
    GiftItem(id: "l4", name: "Lucky Island", price: 10000, icon: "🏝️", category: GiftCategory.lucky),

    // --- 3. Luxury ምድብ (70% ዳይመንድ) ---
    GiftItem(id: "lx1", name: "Sports Car", price: 5000, icon: "🏎️", category: GiftCategory.luxury),
    GiftItem(id: "lx2", name: "Super Yacht", price: 20000, icon: "🛥️", category: GiftCategory.luxury),
    GiftItem(id: "lx3", name: "Private Jet", price: 50000, icon: "✈️", category: GiftCategory.luxury),

    // --- 4. Intimacy ምድብ (70% ዳይመንድ) ---
    GiftItem(id: "i1", name: "Teddy Bear", price: 300, icon: "🧸", category: GiftCategory.intimacy),
    GiftItem(id: "i2", name: "Love Castle", price: 8000, icon: "🏰", category: GiftCategory.intimacy),
  ];
}
