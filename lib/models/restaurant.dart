class Restaurant {
  final String name;
  final String address;
  final String description;
  final String cuisine;
  final int established;
  final List<MenuCategory> menu;
  final List<String> highlights;
  final List<String> signatureDishes;
  final List<String> tags;

  Restaurant({
    required this.name,
    required this.address,
    required this.description,
    required this.cuisine,
    required this.established,
    required this.menu,
    required this.highlights,
    required this.signatureDishes,
    required this.tags,
  });
}

class MenuCategory {
  final String name;
  final List<MenuItem> items;

  MenuCategory({
    required this.name,
    required this.items,
  });
}

class MenuItem {
  final String name;
  final dynamic price;

  MenuItem({
    required this.name,
    required this.price,
  });
} 