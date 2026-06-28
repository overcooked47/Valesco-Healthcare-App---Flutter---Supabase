import '../core/utils/uuid_helper.dart';

/// Represents a single meal recommendation
class MealRecommendation {
  final String name;
  final String category; // breakfast, lunch, dinner, snack
  final String description;
  final String healthBenefit;
  final List<String> ingredients;
  final int calories;
  final String prepTime;

  MealRecommendation({
    required this.name,
    required this.category,
    this.description = '',
    this.healthBenefit = '',
    this.ingredients = const [],
    this.calories = 0,
    this.prepTime = '',
  });

  factory MealRecommendation.fromJson(Map<String, dynamic> json) {
    return MealRecommendation(
      name: json['name'] ?? '',
      category: json['category'] ?? 'lunch',
      description: json['description'] ?? '',
      healthBenefit: json['health_benefit'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      calories: json['calories'] ?? 0,
      prepTime: json['prep_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'health_benefit': healthBenefit,
      'ingredients': ingredients,
      'calories': calories,
      'prep_time': prepTime,
    };
  }
}

/// Represents a daily meal plan (all meals for one day)
class DailyMealPlan {
  final String dayName; // Monday, Tuesday, etc.
  final List<MealRecommendation> meals;

  DailyMealPlan({
    required this.dayName,
    required this.meals,
  });

  List<MealRecommendation> get breakfast =>
      meals.where((m) => m.category == 'breakfast').toList();
  List<MealRecommendation> get lunch =>
      meals.where((m) => m.category == 'lunch').toList();
  List<MealRecommendation> get dinner =>
      meals.where((m) => m.category == 'dinner').toList();
  List<MealRecommendation> get snacks =>
      meals.where((m) => m.category == 'snack').toList();

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      dayName: json['day_name'] ?? '',
      meals: (json['meals'] as List?)
              ?.map((m) => MealRecommendation.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_name': dayName,
      'meals': meals.map((m) => m.toJson()).toList(),
    };
  }
}

/// Full diet recommendation result from the ML backend
class DietRecommendation {
  final String id;
  final String planName;
  final String dailyGuidelines;
  final List<DailyMealPlan> weeklyPlan;
  final Map<String, double> inputMetrics;
  final DateTime createdAt;
  final bool isCached;

  DietRecommendation({
    String? id,
    required this.planName,
    required this.dailyGuidelines,
    required this.weeklyPlan,
    this.inputMetrics = const {},
    DateTime? createdAt,
    this.isCached = false,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now();

  /// Get today's meal plan
  DailyMealPlan? get todayPlan {
    final today = _dayNames[DateTime.now().weekday - 1];
    try {
      return weeklyPlan.firstWhere(
        (p) => p.dayName.toLowerCase() == today.toLowerCase(),
      );
    } catch (_) {
      return weeklyPlan.isNotEmpty ? weeklyPlan.first : null;
    }
  }

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  factory DietRecommendation.fromApiResponse(Map<String, dynamic> json) {
    final recommendation = json['recommendation'] ?? json;
    final metrics = json['input_metrics'] ?? {};

    // Parse weekly_meals from the backend (simple strings) into structured meal plans
    final weeklyMeals = recommendation['weekly_meals'] as List? ?? [];
    final planName = recommendation['plan_name'] ?? 'Personalized Diet Plan';
    final dailyGuidelines = recommendation['daily_guidelines'] ?? '';

    // Build weekly plan from the backend's weekly_meals array
    final weeklyPlan = _buildWeeklyPlan(weeklyMeals, planName);

    return DietRecommendation(
      planName: planName,
      dailyGuidelines: dailyGuidelines,
      weeklyPlan: weeklyPlan,
      inputMetrics: Map<String, double>.from(
        metrics.map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }

  /// Build a full weekly plan from the backend's simple meal strings
  static List<DailyMealPlan> _buildWeeklyPlan(
      List<dynamic> weeklyMeals, String planName) {
    // The backend returns strings like "Monday: Grilled chicken with quinoa..."
    // Parse those and also generate additional meals for a complete week

    final Map<String, List<MealRecommendation>> dayMeals = {};

    for (final dayName in _dayNames) {
      dayMeals[dayName] = [];
    }

    // Parse backend meals
    for (final meal in weeklyMeals) {
      final mealStr = meal.toString();
      final colonIndex = mealStr.indexOf(':');
      if (colonIndex > 0) {
        final dayName = mealStr.substring(0, colonIndex).trim();
        final mealDescription = mealStr.substring(colonIndex + 1).trim();

        // Find matching day
        for (final day in _dayNames) {
          if (day.toLowerCase() == dayName.toLowerCase()) {
            dayMeals[day]!.add(MealRecommendation(
              name: mealDescription,
              category: 'lunch',
              description: mealDescription,
              healthBenefit: _getHealthBenefit(planName, mealDescription),
            ));
            break;
          }
        }
      }
    }

    // Generate complete meal plans for all 7 days
    final completePlan = <DailyMealPlan>[];
    for (final dayName in _dayNames) {
      final existingMeals = dayMeals[dayName] ?? [];
      final fullDayMeals = _generateFullDayMeals(
          dayName, existingMeals, planName);
      completePlan.add(DailyMealPlan(
        dayName: dayName,
        meals: fullDayMeals,
      ));
    }

    return completePlan;
  }

  /// Generate a full day of meals including breakfast, lunch, dinner, snacks
  static List<MealRecommendation> _generateFullDayMeals(
    String dayName,
    List<MealRecommendation> existingLunches,
    String planName,
  ) {
    final meals = <MealRecommendation>[];
    final dayIndex = _dayNames.indexOf(dayName);

    // Breakfast options by plan type
    final breakfasts = _getBreakfastOptions(planName);
    meals.add(MealRecommendation(
      name: breakfasts[dayIndex % breakfasts.length]['name']!,
      category: 'breakfast',
      description: breakfasts[dayIndex % breakfasts.length]['description']!,
      healthBenefit: breakfasts[dayIndex % breakfasts.length]['benefit']!,
      calories: 350,
      prepTime: '15 min',
    ));

    // Use existing lunch or generate one
    if (existingLunches.isNotEmpty) {
      for (final lunch in existingLunches) {
        meals.add(MealRecommendation(
          name: lunch.name,
          category: 'lunch',
          description: lunch.description,
          healthBenefit: lunch.healthBenefit,
          calories: 500,
          prepTime: '30 min',
        ));
      }
    } else {
      final lunches = _getLunchOptions(planName);
      meals.add(MealRecommendation(
        name: lunches[dayIndex % lunches.length]['name']!,
        category: 'lunch',
        description: lunches[dayIndex % lunches.length]['description']!,
        healthBenefit: lunches[dayIndex % lunches.length]['benefit']!,
        calories: 500,
        prepTime: '30 min',
      ));
    }

    // Dinner options
    final dinners = _getDinnerOptions(planName);
    meals.add(MealRecommendation(
      name: dinners[dayIndex % dinners.length]['name']!,
      category: 'dinner',
      description: dinners[dayIndex % dinners.length]['description']!,
      healthBenefit: dinners[dayIndex % dinners.length]['benefit']!,
      calories: 450,
      prepTime: '25 min',
    ));

    // Snack
    final snacks = _getSnackOptions(planName);
    meals.add(MealRecommendation(
      name: snacks[dayIndex % snacks.length]['name']!,
      category: 'snack',
      description: snacks[dayIndex % snacks.length]['description']!,
      healthBenefit: snacks[dayIndex % snacks.length]['benefit']!,
      calories: 150,
      prepTime: '5 min',
    ));

    return meals;
  }

  static String _getHealthBenefit(String planName, String meal) {
    final lower = planName.toLowerCase();
    if (lower.contains('diabetic')) {
      return 'Low glycemic index helps stabilize blood sugar levels';
    } else if (lower.contains('dash') || lower.contains('hypertension')) {
      return 'Low sodium content supports healthy blood pressure';
    } else if (lower.contains('combined')) {
      return 'Low glycemic + low sodium for dual condition management';
    }
    return 'Balanced nutrition supporting overall health';
  }

  static List<Map<String, String>> _getBreakfastOptions(String planName) {
    final lower = planName.toLowerCase();
    if (lower.contains('diabetic') || lower.contains('combined')) {
      return [
        {'name': 'Greek Yogurt with Berries & Chia Seeds', 'description': 'Low-sugar Greek yogurt topped with fresh blueberries and chia seeds', 'benefit': 'Low glycemic breakfast that provides sustained energy without blood sugar spikes'},
        {'name': 'Spinach & Mushroom Egg White Omelette', 'description': 'Fluffy egg white omelette with spinach, mushrooms, and a sprinkle of feta', 'benefit': 'High protein, low carb meal to maintain stable glucose levels'},
        {'name': 'Overnight Oats with Cinnamon & Walnuts', 'description': 'Steel-cut oats soaked overnight with cinnamon and walnuts', 'benefit': 'Cinnamon helps improve insulin sensitivity; fiber promotes satiety'},
        {'name': 'Avocado Toast on Whole Grain Bread', 'description': 'Mashed avocado on whole grain toast with a poached egg', 'benefit': 'Healthy fats and complex carbs for slow-release energy'},
        {'name': 'Cottage Cheese with Flaxseeds & Berries', 'description': 'Low-fat cottage cheese with ground flaxseeds and mixed berries', 'benefit': 'High protein with omega-3 fatty acids for heart health'},
        {'name': 'Vegetable Smoothie Bowl', 'description': 'Blended spinach, cucumber, avocado, and unsweetened almond milk', 'benefit': 'Nutrient-dense with minimal impact on blood sugar'},
        {'name': 'Almond Flour Pancakes with Sugar-Free Syrup', 'description': 'Fluffy almond flour pancakes with a drizzle of sugar-free maple syrup', 'benefit': 'Low-carb alternative that satisfies without glucose spikes'},
      ];
    } else if (lower.contains('dash')) {
      return [
        {'name': 'Banana Oatmeal with Almonds', 'description': 'Warm oatmeal with sliced banana and unsalted almonds', 'benefit': 'Potassium-rich banana supports blood pressure regulation'},
        {'name': 'Whole Wheat Toast with Avocado', 'description': 'Unsalted whole wheat toast with mashed avocado and tomato', 'benefit': 'Heart-healthy fats with potassium for BP management'},
        {'name': 'Fresh Fruit Smoothie', 'description': 'Blended mango, banana, and low-fat yogurt', 'benefit': 'High potassium and calcium support cardiovascular health'},
        {'name': 'Scrambled Eggs with Vegetables', 'description': 'Scrambled eggs with bell peppers and spinach, no added salt', 'benefit': 'Protein-rich with vegetables providing essential minerals'},
        {'name': 'Mixed Berry Bowl with Granola', 'description': 'Fresh mixed berries with unsalted homemade granola', 'benefit': 'Antioxidants from berries support vascular health'},
        {'name': 'Sweet Potato Hash', 'description': 'Diced sweet potato with onions and herbs', 'benefit': 'High potassium and fiber for heart health'},
        {'name': 'Yogurt Parfait with Honey', 'description': 'Low-fat yogurt layered with fresh fruit and a touch of honey', 'benefit': 'Calcium and probiotics supporting overall cardiovascular function'},
      ];
    }
    // Standard balanced diet
    return [
      {'name': 'Whole Grain Cereal with Fresh Fruit', 'description': 'High-fiber cereal with sliced banana and low-fat milk', 'benefit': 'Balanced nutrients to fuel your morning'},
      {'name': 'Veggie Breakfast Wrap', 'description': 'Whole wheat wrap with scrambled eggs, peppers, and cheese', 'benefit': 'Complete protein with complex carbohydrates'},
      {'name': 'Oatmeal with Mixed Berries', 'description': 'Steel-cut oatmeal topped with strawberries and blueberries', 'benefit': 'Heart-healthy fiber with antioxidant-rich berries'},
      {'name': 'Eggs Benedict on English Muffin', 'description': 'Poached eggs with light hollandaise on a whole grain muffin', 'benefit': 'Protein-packed meal for sustained energy'},
      {'name': 'Smoothie Bowl with Granola', 'description': 'Acai smoothie bowl topped with granola and fresh fruit', 'benefit': 'Rich in vitamins and minerals for immune support'},
      {'name': 'Pancakes with Fresh Fruit', 'description': 'Whole wheat pancakes with fresh strawberries', 'benefit': 'Complex carbohydrates for morning energy'},
      {'name': 'Toast with Peanut Butter & Banana', 'description': 'Whole grain toast with natural peanut butter and sliced banana', 'benefit': 'Healthy fats and protein for lasting fullness'},
    ];
  }

  static List<Map<String, String>> _getLunchOptions(String planName) {
    final lower = planName.toLowerCase();
    if (lower.contains('diabetic') || lower.contains('combined')) {
      return [
        {'name': 'Grilled Chicken Caesar Salad', 'description': 'Romaine lettuce with grilled chicken, parmesan, and light dressing', 'benefit': 'Low carb with high protein for blood sugar stability'},
        {'name': 'Turkey & Avocado Lettuce Wraps', 'description': 'Sliced turkey with avocado wrapped in butter lettuce', 'benefit': 'Carb-free wrap keeps glucose levels steady'},
        {'name': 'Lentil & Vegetable Soup', 'description': 'Hearty lentil soup with carrots, celery, and herbs', 'benefit': 'High fiber lentils promote slow glucose absorption'},
        {'name': 'Quinoa Bowl with Grilled Vegetables', 'description': 'Quinoa base with roasted zucchini, bell peppers, and feta', 'benefit': 'Complete protein quinoa with low glycemic vegetables'},
        {'name': 'Salmon Poke Bowl', 'description': 'Fresh salmon over cauliflower rice with cucumber and avocado', 'benefit': 'Omega-3 rich fish improves insulin sensitivity'},
        {'name': 'Mediterranean Chickpea Salad', 'description': 'Chickpeas with cucumber, tomato, olives, and olive oil dressing', 'benefit': 'Fiber-rich chickpeas for sustained energy'},
        {'name': 'Stuffed Bell Peppers', 'description': 'Bell peppers stuffed with ground turkey and vegetables', 'benefit': 'Low carb vessel with lean protein'},
      ];
    } else if (lower.contains('dash')) {
      return [
        {'name': 'Grilled Chicken & Quinoa Bowl', 'description': 'Seasoned chicken with quinoa and steamed vegetables, no salt', 'benefit': 'High potassium and magnesium for blood pressure control'},
        {'name': 'Black Bean & Corn Salad', 'description': 'Black beans, corn, tomato, and cilantro with lime dressing', 'benefit': 'Potassium and fiber support cardiovascular health'},
        {'name': 'Turkey Sandwich on Whole Wheat', 'description': 'Unsalted turkey with lettuce, tomato, and mustard', 'benefit': 'Lean protein with low sodium for heart health'},
        {'name': 'Vegetable Stir-Fry with Brown Rice', 'description': 'Mixed vegetables stir-fried with low-sodium soy sauce', 'benefit': 'Rich in potassium and fiber with minimal sodium'},
        {'name': 'Tuna Salad with Mixed Greens', 'description': 'Low-sodium tuna with mixed greens and vinaigrette', 'benefit': 'Omega-3s support arterial flexibility'},
        {'name': 'Minestrone Soup', 'description': 'Low-sodium vegetable soup with whole grain pasta', 'benefit': 'Nutrient-dense with multiple servings of vegetables'},
        {'name': 'Chicken & Spinach Wrap', 'description': 'Grilled chicken with spinach in a whole wheat tortilla', 'benefit': 'Magnesium-rich spinach helps regulate blood pressure'},
      ];
    }
    return [
      {'name': 'Mediterranean Chicken Bowl', 'description': 'Grilled chicken with hummus, falafel, and fresh vegetables', 'benefit': 'Balanced macronutrients with heart-healthy olive oil'},
      {'name': 'Asian Salmon Bowl', 'description': 'Teriyaki salmon with edamame and brown rice', 'benefit': 'Omega-3 fatty acids support brain and heart health'},
      {'name': 'Chicken Caesar Wrap', 'description': 'Grilled chicken with romaine and light Caesar dressing', 'benefit': 'Lean protein for muscle maintenance and energy'},
      {'name': 'Vegetable Pasta Primavera', 'description': 'Whole wheat pasta with seasonal grilled vegetables', 'benefit': 'Complex carbs with fiber from vegetables'},
      {'name': 'Tuna Nicoise Salad', 'description': 'Tuna with green beans, eggs, and olive dressing', 'benefit': 'Protein-rich meal with healthy monounsaturated fats'},
      {'name': 'Turkey & Cranberry Sandwich', 'description': 'Roasted turkey with cranberry sauce on whole grain bread', 'benefit': 'Lean protein with antioxidant-rich cranberries'},
      {'name': 'Shrimp Stir-Fry with Vegetables', 'description': 'Shrimp stir-fried with broccoli, peppers, and ginger', 'benefit': 'Low calorie protein with immune-boosting ginger'},
    ];
  }

  static List<Map<String, String>> _getDinnerOptions(String planName) {
    final lower = planName.toLowerCase();
    if (lower.contains('diabetic') || lower.contains('combined')) {
      return [
        {'name': 'Baked Salmon with Asparagus', 'description': 'Wild-caught salmon fillet with roasted asparagus spears', 'benefit': 'Omega-3s reduce inflammation and improve insulin response'},
        {'name': 'Chicken Stir-Fry with Cauliflower Rice', 'description': 'Lean chicken with vegetables over riced cauliflower', 'benefit': 'Very low carb dinner for overnight glucose control'},
        {'name': 'Turkey Meatballs with Zucchini Noodles', 'description': 'Seasoned turkey meatballs over spiralized zucchini', 'benefit': 'Low carb noodle alternative minimizes blood sugar impact'},
        {'name': 'Grilled Tofu with Steamed Broccoli', 'description': 'Marinated tofu with steamed broccoli and sesame seeds', 'benefit': 'Plant protein with chromium-rich broccoli for glucose metabolism'},
        {'name': 'Herb-Crusted Cod with Green Beans', 'description': 'Baked cod with a herb crust and steamed green beans', 'benefit': 'Lean white fish with fiber-rich vegetables'},
        {'name': 'Stuffed Portobello Mushrooms', 'description': 'Mushroom caps stuffed with spinach, tomato, and cheese', 'benefit': 'Low calorie, nutrient-dense dinner option'},
        {'name': 'Lemon Herb Chicken with Mixed Vegetables', 'description': 'Baked chicken thigh with lemon, herbs, and roasted vegetables', 'benefit': 'Lean protein with vitamin C supporting immune health'},
      ];
    } else if (lower.contains('dash')) {
      return [
        {'name': 'Baked Cod with Roasted Vegetables', 'description': 'Unsalted baked cod with roasted Brussels sprouts and carrots', 'benefit': 'Low sodium dinner rich in omega-3s for heart health'},
        {'name': 'Herb Roasted Chicken', 'description': 'Chicken breast with rosemary and thyme, no added salt', 'benefit': 'Herbs replace salt while adding antioxidant properties'},
        {'name': 'Vegetable Curry with Brown Rice', 'description': 'Mild vegetable curry with turmeric and brown rice', 'benefit': 'Turmeric has anti-inflammatory benefits for cardiovascular health'},
        {'name': 'Grilled Shrimp Skewers', 'description': 'Lemon-herb shrimp with grilled zucchini and squash', 'benefit': 'Low fat protein with potassium-rich vegetables'},
        {'name': 'Salmon with Sweet Potato', 'description': 'Baked salmon with roasted sweet potato wedges', 'benefit': 'Potassium and omega-3s work together to lower blood pressure'},
        {'name': 'Turkey Chili', 'description': 'Low-sodium turkey chili with beans and tomatoes', 'benefit': 'Beans provide potassium and fiber for BP management'},
        {'name': 'Pasta with Tomato & Basil Sauce', 'description': 'Whole grain pasta with fresh tomato sauce and basil', 'benefit': 'Lycopene in tomatoes supports heart health'},
      ];
    }
    return [
      {'name': 'Grilled Chicken with Sweet Potato', 'description': 'Herb-marinated chicken with roasted sweet potato', 'benefit': 'Complete meal with lean protein and complex carbs'},
      {'name': 'Baked Salmon with Quinoa', 'description': 'Lemon-dill salmon with fluffy quinoa and salad', 'benefit': 'Heart-healthy omega-3s with complete plant protein'},
      {'name': 'Beef Stir-Fry with Vegetables', 'description': 'Lean beef strips with colorful vegetables and brown rice', 'benefit': 'Iron-rich meal supporting oxygen transport'},
      {'name': 'Grilled Fish Tacos', 'description': 'Grilled white fish in corn tortillas with slaw', 'benefit': 'Lean protein with probiotic-rich fermented slaw'},
      {'name': 'Chicken Tikka with Naan', 'description': 'Spiced chicken tikka with whole wheat naan and raita', 'benefit': 'Spices contain anti-inflammatory compounds'},
      {'name': 'Pasta Bolognese', 'description': 'Whole wheat pasta with lean meat sauce and vegetables', 'benefit': 'Balanced carbs and protein for muscle recovery'},
      {'name': 'Vegetable Lasagna', 'description': 'Layered lasagna with ricotta, spinach, and tomato sauce', 'benefit': 'Calcium and lycopene for bone and heart health'},
    ];
  }

  static List<Map<String, String>> _getSnackOptions(String planName) {
    final lower = planName.toLowerCase();
    if (lower.contains('diabetic') || lower.contains('combined')) {
      return [
        {'name': 'Handful of Mixed Nuts', 'description': 'Almonds, walnuts, and pecans', 'benefit': 'Healthy fats stabilize blood sugar between meals'},
        {'name': 'Celery Sticks with Almond Butter', 'description': 'Fresh celery with a tablespoon of almond butter', 'benefit': 'Low carb snack with healthy monounsaturated fats'},
        {'name': 'Hard-Boiled Eggs', 'description': 'Two hard-boiled eggs with a dash of pepper', 'benefit': 'Protein-rich snack with zero carb impact'},
        {'name': 'Cheese & Cucumber Slices', 'description': 'Low-fat cheese with fresh cucumber rounds', 'benefit': 'Hydrating snack with calcium and minimal carbs'},
        {'name': 'Sugar-Free Greek Yogurt', 'description': 'Plain Greek yogurt with a sprinkle of cinnamon', 'benefit': 'Probiotics support gut health; cinnamon aids glucose control'},
        {'name': 'Cherry Tomatoes with Mozzarella', 'description': 'Fresh cherry tomatoes with mini mozzarella balls', 'benefit': 'Low glycemic snack rich in lycopene and calcium'},
        {'name': 'Edamame', 'description': 'Steamed edamame pods lightly salted', 'benefit': 'Plant protein with fiber for blood sugar stability'},
      ];
    } else if (lower.contains('dash')) {
      return [
        {'name': 'Fresh Fruit Slices', 'description': 'Sliced apple and pear', 'benefit': 'Potassium and fiber support blood pressure'},
        {'name': 'Unsalted Trail Mix', 'description': 'Nuts, seeds, and dried cranberries without added salt', 'benefit': 'Magnesium from nuts helps relax blood vessels'},
        {'name': 'Yogurt with Honey', 'description': 'Low-fat yogurt drizzled with raw honey', 'benefit': 'Calcium supports healthy blood pressure levels'},
        {'name': 'Carrot & Hummus', 'description': 'Baby carrots with low-sodium hummus', 'benefit': 'Potassium from carrots aids BP regulation'},
        {'name': 'Banana with Peanut Butter', 'description': 'Banana slices with unsalted peanut butter', 'benefit': 'High potassium banana is a DASH diet staple'},
        {'name': 'Rice Cakes with Avocado', 'description': 'Unsalted rice cakes with mashed avocado', 'benefit': 'Heart-healthy fats with minimal sodium'},
        {'name': 'Mixed Berries', 'description': 'Fresh strawberries, blueberries, and raspberries', 'benefit': 'Anthocyanins support vascular health'},
      ];
    }
    return [
      {'name': 'Apple with Peanut Butter', 'description': 'Sliced apple with natural peanut butter', 'benefit': 'Fiber and healthy fats keep you full'},
      {'name': 'Mixed Nuts & Dried Fruit', 'description': 'Almonds, cashews with raisins', 'benefit': 'Healthy fats and quick energy from natural sugars'},
      {'name': 'Greek Yogurt with Honey', 'description': 'Creamy Greek yogurt with a drizzle of honey', 'benefit': 'Probiotics for gut health and protein for satiety'},
      {'name': 'Hummus with Veggie Sticks', 'description': 'Creamy hummus with carrot and celery sticks', 'benefit': 'Plant protein with fiber-rich vegetables'},
      {'name': 'Dark Chocolate & Almonds', 'description': 'A few squares of dark chocolate with almonds', 'benefit': 'Antioxidants from cocoa support heart health'},
      {'name': 'Fresh Fruit Salad', 'description': 'Seasonal fruits diced and mixed', 'benefit': 'Vitamins and minerals from diverse fruit sources'},
      {'name': 'Protein Energy Balls', 'description': 'Oat, honey, and nut butter energy bites', 'benefit': 'Sustained energy from complex carbs and protein'},
    ];
  }

  factory DietRecommendation.fromCacheJson(Map<String, dynamic> json) {
    return DietRecommendation(
      id: json['id'],
      planName: json['plan_name'] ?? '',
      dailyGuidelines: json['daily_guidelines'] ?? '',
      weeklyPlan: (json['weekly_plan'] as List?)
              ?.map((d) => DailyMealPlan.fromJson(d))
              .toList() ??
          [],
      inputMetrics: Map<String, double>.from(
        (json['input_metrics'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isCached: true,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'plan_name': planName,
      'daily_guidelines': dailyGuidelines,
      'weekly_plan': weeklyPlan.map((d) => d.toJson()).toList(),
      'input_metrics': inputMetrics,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// User dietary preferences passed to the ML model
class DietaryPreferences {
  final List<String> foodAllergies;
  final List<String> dietaryRestrictions; // vegetarian, vegan, halal, etc.
  final List<String> dislikedFoods;
  final int? targetCalories;

  DietaryPreferences({
    this.foodAllergies = const [],
    this.dietaryRestrictions = const [],
    this.dislikedFoods = const [],
    this.targetCalories,
  });

  Map<String, dynamic> toJson() {
    return {
      'food_allergies': foodAllergies,
      'dietary_restrictions': dietaryRestrictions,
      'disliked_foods': dislikedFoods,
      'target_calories': targetCalories,
    };
  }

  factory DietaryPreferences.fromJson(Map<String, dynamic> json) {
    return DietaryPreferences(
      foodAllergies: List<String>.from(json['food_allergies'] ?? []),
      dietaryRestrictions:
          List<String>.from(json['dietary_restrictions'] ?? []),
      dislikedFoods: List<String>.from(json['disliked_foods'] ?? []),
      targetCalories: json['target_calories'],
    );
  }

  DietaryPreferences copyWith({
    List<String>? foodAllergies,
    List<String>? dietaryRestrictions,
    List<String>? dislikedFoods,
    int? targetCalories,
  }) {
    return DietaryPreferences(
      foodAllergies: foodAllergies ?? this.foodAllergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      targetCalories: targetCalories ?? this.targetCalories,
    );
  }
}
