import 'package:fyp_scaneat_cc/models/restaurant.dart';

// Custom restaurants storage
List<Map<String, dynamic>> _customRestaurants = [];

// Function to add a custom restaurant
void addCustomRestaurant(Map<String, dynamic> restaurant) {
  _customRestaurants.add(restaurant);
}

// Function to get all custom restaurants
List<Map<String, dynamic>> getCustomRestaurants() {
  return List<Map<String, dynamic>>.from(_customRestaurants);
}

// Function to clear all custom restaurants (for testing)
void clearCustomRestaurants() {
  _customRestaurants.clear();
}

// Function to delete a custom restaurant
void deleteCustomRestaurant(int index) {
  if (index >= 0 && index < _customRestaurants.length) {
    _customRestaurants.removeAt(index);
  }
}

// Default restaurant data
final restaurantInfoEn = {
  "name": "Oi Man Sang",
  "address": "Sham Shui Po Building, 1A-1C Shek Kip Mei St, Sham Shui Po, Hong Kong",
  "description": "Specializing in Cantonese cuisine, Oi Man Sang is as unfussy and unpretentious as it gets. It has been a staple in Sham Shui Po since 1956, making it one of the oldest 'dai pai dongs' (open-air food stalls) in all of Hong Kong. The menu has changed little over the years, and the restaurant still serves authentic local fare. Some of the most popular dishes include salt and pepper squid, garlic steamed razor clams, potato and beef stir fry, and salted egg yolk prawns.",
  "cuisine": "Cantonese",
  "established": 1956,
};

final menuEn = {
  "categories": [
    {
      "name": "Popular Dishes",
      "items": [
        {"name": "Spicy Crab", "price": "Market Price"},
        {"name": "Salted Egg Yolk Prawns", "price": "Market Price"},
        {"name": "Garlic Steamed Razor Clams", "price": 208},
        {"name": "Black Pepper Pig Knuckle", "price": 178},
        {"name": "Stir-Fried Potato and Beef", "price": 88},
        {"name": "Salt and Pepper Squid", "price": 128},
        {"name": "Shunde Style Stir-Fried Fresh Milk", "price": 138},
        {"name": "Yangzhou Fried Rice", "price": 78},
      ],
    },
  ],
};

final additionalDetailsEn = {
  "highlights": [
    "Authentic Cantonese cuisine",
    "One of the oldest dai pai dongs in Hong Kong",
    "Famous for fresh seafood and local delicacies",
  ],
  "signatureDishes": [
    "Salted Egg Yolk Prawns",
    "Salt and Pepper Squid",
    "Garlic Steamed Razor Clams",
  ],
  "tags": [
    "Cantonese Cuisine",
    "Seafood",
    "Historic Restaurant",
    "Sham Shui Po",
    "Affordable Eats"
  ],
};

final restaurantInfoKo = {
  "name": "오이 만 상 (Oi Man Sang)",
  "address": "홍콩 Sham Shui Po, Shek Kip Mei St 1A-1C Sham Shui Po Building",
  "description": "광동 요리를 전문으로 하는 오이 만 상은 간단하고 꾸밈없는 매력을 자랑합니다. 1956년부터 Sham Shui Po 지역에서 사랑받아온 이곳은 홍콩에서 가장 오래된 '다이 파이 동' (천 음식점) 중 하나입니다. 메뉴는 수년간 거의 변하지 않았으며, 여전히 정통 로컬 요리를 제공합니다. 가장 인기 있는 요리로는 소과 후추를 곁들인 오징어, 마늘로 찐 대합조개, 감자와 소고기 볶음, 그리고 소금에 절인 계란 노른자 새우 요리가 있습니다.",
  "cuisine": "광동 요리",
  "established": 1956,
};

final menuKo = {
  "categories": [
    {
      "name": "인기 요리",
      "items": [
        {"name": "매운 게", "price": "시장 가격"},
        {"name": "소금에 절인 계란 노른자 새우", "price": "시장 가격"},
        {"name": "마늘 찜 대합조개", "price": 208},
        {"name": "흑후추 족발", "price": 178},
        {"name": "감자와 소고기 볶음", "price": 88},
        {"name": "소금과 후추 오징어", "price": 128},
        {"name": "순더 스타일 신선한 우유 볶음", "price": 138},
        {"name": "양저우 볶음밥", "price": 78},
      ],
    },
  ],
};

final additionalDetailsKo = {
  "highlights": [
    "정통 광동 요리",
    "홍콩에서 가장 오래된 다이 파이 동 중 하나",
    "신선한 해산물과 로컬 별미로 유명",
  ],
  "signatureDishes": [
    "소금에 절인 계란 노른자 새우",
    "소금과 후추 오징어",
    "마늘 찜 대합조개",
  ],
  "tags": [
    "광동 요리",
    "해산물",
    "역적인 레스토랑",
    "Sham Shui Po",
    "합리적인 가격"
  ],
};

// One Dim Sum Restaurant Data
final oneDimSumInfoEn = {
  "name": "One Dim Sum",
  "address": "G/F, 44 Lyndhurst Terrace, Central, Hong Kong",
  "description": "A renowned dim sum restaurant specializing in authentic and affordable dim sum dishes, highly rated at 4.6/5 by 286 reviews.",
  "cuisine": "Dim Sum",
  "rating": 4.6,
};

final oneDimSumMenuEn = {
  "categories": [
    {
      "name": "Dim Sum",
      "items": [
        {"name": "Shrimp Dumplings (Har Gow)", "price": 16},
        {"name": "Pork and Shrimp Dumplings (Siu Mai)", "price": 16},
        {"name": "BBQ Pork Bun", "price": 13},
        {"name": "Steamed Rice Rolls", "price": 20},
      ],
    },
  ],
};

final oneDimSumDetailsEn = {
  "highlights": [
    "Affordable and authentic dim sum",
    "Perfect for casual dining",
    "Highly rated for taste and quality",
  ],
  "signatureDishes": [
    "Shrimp Dumplings (Har Gow)",
    "BBQ Pork Bun",
    "Steamed Rice Rolls",
  ],
  "tags": [
    "Dim Sum",
    "Affordable",
    "Central",
  ],
};

final oneDimSumInfoKo = {
  "name": "원 딤섬 (One Dim Sum)",
  "address": "홍콩 센트럴, 린드허스트 테라스 44번지 G/F",
  "description": "정통 딤섬을 합리적인 가격에 제공하는 유명 딤섬 레스토랑으로, 286개의 리뷰에서 4.6/5점의 높은 평가를 받았습니다.",
  "cuisine": "딤섬",
  "rating": 4.6,
};

final oneDimSumMenuKo = {
  "categories": [
    {
      "name": "딤섬",
      "items": [
        {"name": "새우 만두 (하카우)", "price": 16},
        {"name": "돼지고기 새우 만두 (슈마이)", "price": 16},
        {"name": "차슈 번", "price": 13},
        {"name": "쌀국수", "price": 20},
      ],
    },
  ],
};

final oneDimSumDetailsKo = {
  "highlights": [
    "합리적인 가격의 정통 딤섬",
    "캐주얼 식사에 적합",
    "맛과 품질에서 높은 평가",
  ],
  "signatureDishes": [
    "새우 만두 (하카우)",
    "차슈 번",
    "쌀국수",
  ],
  "tags": [
    "딤섬",
    "합리적인 가격",
    "센트럴",
  ],
};

// Function to get restaurant data
Map<String, dynamic> getRestaurantData(String restaurantName, String language) {
  // First check custom restaurants
  try {
    final customRestaurant = _customRestaurants.firstWhere(
      (r) => r['info']['name'].toString().toLowerCase() == restaurantName.toLowerCase(),
    );
    return customRestaurant;
  } catch (e) {
    // Then check predefined restaurants
    switch (restaurantName.toLowerCase()) {
      case 'oi man sang':
        return {
          'info': language == 'ko' ? restaurantInfoKo : restaurantInfoEn,
          'menu': language == 'ko' ? menuKo : menuEn,
          'details': language == 'ko' ? additionalDetailsKo : additionalDetailsEn,
        };
      case 'one dim sum':
        return {
          'info': language == 'ko' ? oneDimSumInfoKo : oneDimSumInfoEn,
          'menu': language == 'ko' ? oneDimSumMenuKo : oneDimSumMenuEn,
          'details': language == 'ko' ? oneDimSumDetailsKo : oneDimSumDetailsEn,
        };
      default:
        throw Exception('Restaurant not found');
    }
  }
}

// Function to get all restaurants
List<Map<String, dynamic>> getAllRestaurants(String language) {
  final List<Map<String, dynamic>> allRestaurants = [
    getRestaurantData('oi man sang', language),
    getRestaurantData('one dim sum', language),
    ..._customRestaurants,
  ];
  return allRestaurants;
}

// Default to English
var restaurant = restaurantInfoEn;
var menu = menuEn;
var additionalDetails = additionalDetailsEn;

// Function to switch language
void switchLanguage(String language) {
  if (language == 'ko') {
    restaurant = restaurantInfoKo;
    menu = menuKo;
    additionalDetails = additionalDetailsKo;
  } else {
    restaurant = restaurantInfoEn;
    menu = menuEn;
    additionalDetails = additionalDetailsEn;
  }
}