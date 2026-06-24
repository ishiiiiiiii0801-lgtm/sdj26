import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Category {
  final String name;
  final IconData icon;

  Category({
    required this.name,
    required this.icon,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '食材管理',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home:FoodHomePage(),
    );
  }
}

class FoodHomePage extends StatelessWidget {
  FoodHomePage({super.key});

  final List<Category> categories =  [
    Category(name: "すべて", icon: Icons.grid_view),
    Category(name: "肉類", icon: Icons.set_meal),
    Category(name: "魚類", icon: Icons.phishing),
    Category(name: "野菜", icon: Icons.eco),
    Category(name: "乳製品", icon: Icons.local_drink),
    Category(name: "主食", icon: Icons.rice_bowl),
    Category(name: "調味料", icon: Icons.kitchen),
    Category(name: "お菓子", icon: Icons.cookie),
    Category(name: "飲料", icon: Icons.water_drop),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("食材一覧"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return CategoryCard(category: categories[index]);
          },
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // 後でカテゴリ画面へ遷移
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}