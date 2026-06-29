import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Resta',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class DetectedFood {
  static const String storageKey = 'temporaryBox';

  final String id;
  final String createdAt;
  final String name;
  int quantity;
  final String category;
  final String expiryDate;
  final String storageMethod;
  final bool isStocked;
  final String memo;

  DetectedFood({
    required this.id,
    required this.createdAt,
    required this.name,
    this.quantity = 1,
    this.category = 'その他',
    this.expiryDate = '',
    this.storageMethod = '冷蔵',
    this.isStocked = false,
    this.memo = '',
  });

  factory DetectedFood.fromJson(Map<String, dynamic> json) {
    return DetectedFood(
      id: json['id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      category: json['category'] ?? 'その他',
      expiryDate: json['expiryDate'] ?? '',
      storageMethod: json['storageMethod'] ?? '冷蔵',
      isStocked: json['isStocked'] ?? false,
      memo: json['memo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'name': name,
        'quantity': quantity,
        'category': category,
        'expiryDate': expiryDate,
        'storageMethod': storageMethod,
        'isStocked': isStocked,
        'memo': memo,
      };

  static Future<void> addToStorage(DetectedFood food) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList(storageKey) ?? [];
    jsonList.insert(0, jsonEncode(food.toJson()));
    await prefs.setStringList(storageKey, jsonList);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resta", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.receipt_long, size: 28),
              label: const Text("レシートを撮影する\n(AIが食材やカテゴリを自動判別)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceiptPage()),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_note, size: 28),
              label: const Text("手入力で登録する\n(最初から詳細を入力して在庫へ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              onPressed: () async {
                final DetectedFood? registeredFood = await Navigator.push<DetectedFood>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoodInputPage(
                      initialFoodName: '',
                      initialQuantity: 1,
                      initialMemo: '',
                      initialCategory: 'other',
                    ),
                  ),
                );
                if (registeredFood != null && context.mounted) {
                  await DetectedFood.addToStorage(registeredFood);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('在庫に登録しました！\n${registeredFood.name}')),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.inventory, size: 28),
              label: const Text("在庫を管理する\n(確認・修正・消費)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptDictionary {
  static final Map<String, String> data = {
    'ｷｬﾍﾞﾂ': '野菜・果物', 'キャベツ': '野菜・果物', 'ﾄﾏﾄ': '野菜・果物', 'トマト': '野菜・果物',
    'ﾀﾏﾈｷﾞ': '野菜・果物', 'たまねぎ': '野菜・果物', '玉ねぎ': '野菜・果物', 'ﾆﾝｼﾞﾝ': '野菜・果物',
    'にんじん': '野菜・果物', '人参': '野菜・果物', 'ﾀﾞｲｺﾝ': '野菜・果物', '大根': '野菜・果物',
    '豚': '肉類', 'ﾎﾟｰｸ': '肉類', '牛肉': '肉類', 'ﾋﾞｰﾌ': '肉類', '鶏': '肉類', 'ﾁｷﾝ': '肉類',
    'ﾐﾝチ': '肉類', 'ひき肉': '肉類', 'ハム': '肉類', 'ｿｰｾｰｼﾞ': '肉類', 'ｳｲﾝﾅｰ': '肉類',
    '鮭': '魚介類', 'ｻｹ': '魚介類', 'マグロ': '魚介類', 'ﾏｸﾞﾛ': '魚介類', 'サバ': '魚介類',
    'ｻﾊﾞ': '魚介類', 'イカ': '魚介類', 'ﾀｺ': '魚介類', 'ちくわ': '魚介類', 'ﾁｸﾜ': '魚介類',
    '牛乳': '乳製品・卵', 'ミルク': '乳製品・卵', 'ﾐﾙｸ': '乳製品・卵', 'ｷﾞｭｳﾆｭｳ': '乳製品・卵', '卵': '乳製品・卵', 'ﾀﾏｺﾞ': '乳製品・卵',
    'ヨーグルト': '乳製品・卵', 'ﾖｰｸﾞﾙﾄ': '乳製品・卵', 'チーズ': '乳製品・卵', 'ﾁｰｽﾞ': '乳製品・卵',
    '食パン': '主食', '食ﾊﾟﾝ': '主食', '米': '主食', 'うどん': '主食', 'ｳﾄﾞﾝ': '主食', 'パスタ': '主食',
  };
}

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool isLoading = false;
  final TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
  final ImagePicker picker = ImagePicker();

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  List<Map<String, String>> _analyzeReceiptTextAll(String fullText) {
    final List<Map<String, String>> candidates = [];
    final List<String> lines = fullText.split('\n').map((l) => l.trim()).toList();

    const List<String> noiseKeywords = [
      '合計', '小計', 'お釣', 'おつり', '現計', '領収','お預かり','お預り','消費税','税','税抜','PayPay','paypay','クレジット','ｸﾚｼﾞｯﾄ',
    ];

    bool hasCurrency(String text) => text.contains(RegExp(r'[￥¥Y円]'));

    for (int i = 0; i < lines.length; i++) {
      final String currentLine = lines[i];
      if (currentLine.isEmpty) continue;

      if (hasCurrency(currentLine) || (i > 0 && hasCurrency(lines[i - 1]))) {
        String potentialName = currentLine;
        if (currentLine.length > 4 && currentLine.contains(RegExp(r'[^\d\s¥￥Y円]'))) {
          final parts = currentLine.split(RegExp(r'[\s¥￥Y円]+'));
          if (parts.isNotEmpty && parts.first.length >= 2) {
            potentialName = parts.first;
          }
        }

        if (potentialName.length >= 2) {
          final bool hasNoise = noiseKeywords.any((noise) => potentialName.contains(noise));
          final bool isPureNumber = RegExp(r'^[0-9,.\s\-+*xX¥￥Y円\(\)]+$').hasMatch(potentialName);

          if (!hasNoise && !isPureNumber) {
            String detectedQuantity = "1";
            final quantityMatch = RegExp(r'(\d+)\s*[点個xX×※]').firstMatch(currentLine);
            if (quantityMatch != null) {
              detectedQuantity = quantityMatch.group(1) ?? "1";
            }

            final matchedKey = ReceiptDictionary.data.keys.firstWhere(
              (key) => potentialName.contains(key),
              orElse: () => '',
            );
            final String category = matchedKey.isNotEmpty ? ReceiptDictionary.data[matchedKey]! : 'その他';

            if (!candidates.any((element) => element['name'] == potentialName)) {
              candidates.add({
                'name': potentialName,
                'category': category,
                'quantity': detectedQuantity,
              });
            }
          }
        }
      }
    }
    return candidates;
  }

  Future<void> scanReceipt(String imagePath) async {
    setState(() => isLoading = true);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

      if (!mounted) return;

      if (fullText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシートから文字を検出できませんでした。')),
        );
        setState(() => isLoading = false);
        return;
      }

      final List<Map<String, String>> detectedCandidates = _analyzeReceiptTextAll(fullText);

      if (detectedCandidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品らしき項目が見つかりませんでした。')),
        );
        setState(() => isLoading = false);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemporaryBoxPage(initialCandidates: detectedCandidates),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> pickAndScanReceipt(ImageSource source) async {
    final image = await picker.pickImage(source: source);
    if (image == null) return;
    await scanReceipt(image.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("レシートスキャン", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("オンデバイスでレシートを解析中...", style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    ),
                  )
                : Column(
                    children: [
                      const Icon(Icons.document_scanner, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "レシートを撮影するかアルバムから選ぶと、自動で中身の食材を判別して詳細画面を開きます。\n(通信は発生しません)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildMenuButton(
                              icon: Icons.camera_alt,
                              label: "カメラで撮影",
                              color: Colors.blue,
                              onPressed: () => pickAndScanReceipt(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMenuButton(
                              icon: Icons.photo_library,
                              label: "アルバムから選ぶ",
                              color: Colors.purple,
                              onPressed: () => pickAndScanReceipt(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class TemporaryBoxPage extends StatefulWidget {
  final List<Map<String, String>> initialCandidates;
  const TemporaryBoxPage({super.key, required this.initialCandidates});

  @override
  State<TemporaryBoxPage> createState() => _TemporaryBoxPageState();
}

class _TemporaryBoxPageState extends State<TemporaryBoxPage> {
  late List<Map<String, String>> _candidates;

  @override
  void initState() {
    super.initState();
    _candidates = List.from(widget.initialCandidates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("レシート読み取り結果 (${_candidates.length}件)", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _candidates.isEmpty
          ? const Center(child: Text("すべての食材の登録が完了しました！", style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final item = _candidates[index];
                final String currentName = item['name'] ?? '';
                final String currentCategory = item['category'] ?? 'その他';
                final int parsedQuantity = int.tryParse(item['quantity'] ?? '1') ?? 1;

                final bool isKnown = ReceiptDictionary.data.containsKey(currentName);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isKnown ? Colors.green[100] : Colors.orange[100],
                      child: Icon(isKnown ? Icons.restaurant : Icons.help_outline, color: isKnown ? Colors.green : Colors.orange),
                    ),
                    title: Text(currentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("推定カテゴリ: $currentCategory ${isKnown ? '(辞書マッチ)' : '(新規候補)'}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () async {
                      final DetectedFood? registeredFood = await Navigator.push<DetectedFood>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodInputPage(
                            initialFoodName: currentName,
                            initialQuantity: parsedQuantity,
                            initialMemo: 'レシート解析（仮BOX経由）',
                            initialCategory: currentCategory,
                          ),
                        ),
                      );
                      if (registeredFood != null && context.mounted) {
                        await DetectedFood.addToStorage(registeredFood);
                        ReceiptDictionary.data[registeredFood.name] = registeredFood.category;
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('『${registeredFood.name}』を在庫に登録し、辞書に記憶しました！')),
                        );
                        setState(() {
                          _candidates.removeAt(index);
                        });
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<DetectedFood> _managedBox = [];

  @override
  void initState() {
    super.initState();
    _loadManagedBox();
  }

  Future<void> _loadManagedBox() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(DetectedFood.storageKey);
    if (jsonList != null) {
      setState(() {
        _managedBox = jsonList.map((jsonStr) => DetectedFood.fromJson(jsonDecode(jsonStr))).toList();
      });
    }
  }

  Future<void> _saveManagedBox() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _managedBox.map((food) => jsonEncode(food.toJson())).toList();
    await prefs.setStringList(DetectedFood.storageKey, jsonList);
  }

  void _reduceQuantity(int originalIndex) async {
    setState(() {
      if (_managedBox[originalIndex].quantity > 1) {
        _managedBox[originalIndex].quantity--;
      } else {
        _managedBox.removeAt(originalIndex);
      }
    });
    await _saveManagedBox();
  }

  void _editFoodInfo(int originalIndex, DetectedFood currentFood) async {
    final DetectedFood? updatedFood = await Navigator.push<DetectedFood>(
      context,
      MaterialPageRoute(
        builder: (context) => FoodInputPage(
          initialFoodName: currentFood.name,
          initialQuantity: currentFood.quantity,
          initialMemo: currentFood.memo,
          initialCategory: currentFood.category,
          existingFood: currentFood,
        ),
      ),
    );
    if (updatedFood != null) {
      setState(() {
        _managedBox[originalIndex] = updatedFood;
      });
      await _saveManagedBox();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('在庫情報を更新しました。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📦 在庫管理 (${_managedBox.length}件)", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _managedBox.isEmpty
          ? const Center(child: Text("登録された在庫はありません", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: _managedBox.length,
              itemBuilder: (context, index) {
                final managedFood = _managedBox[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      leading: const Icon(Icons.inventory, color: Colors.orange),
                      title: Text("${managedFood.name} (${managedFood.quantity}個)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("期限: ${managedFood.expiryDate} / 保管: ${managedFood.storageMethod}", style: const TextStyle(fontSize: 12)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "カテゴリ: ${managedFood.category}\n"
                              "登録日時: ${managedFood.createdAt}\n"
                              "備蓄用: ${managedFood.isStocked ? 'はい' : 'いいえ'}\n"
                              "メモ: ${managedFood.memo.isNotEmpty ? managedFood.memo : 'なし'}",
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: const Text("修正", style: TextStyle(color: Colors.blue)),
                              onPressed: () => _editFoodInfo(index, managedFood),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              label: const Text("1つ減らす", style: TextStyle(color: Colors.red)),
                              onPressed: () => _reduceQuantity(index),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class FoodInputPage extends StatefulWidget {
  final String initialFoodName;
  final int initialQuantity;
  final String initialMemo;
  final String initialCategory;
  final DetectedFood? existingFood;

  const FoodInputPage({
    super.key,
    required this.initialFoodName,
    required this.initialQuantity,
    this.initialMemo = "",
    this.initialCategory = 'その他',
    this.existingFood,
  });

  @override
  State<FoodInputPage> createState() => _FoodInputPageState();
}

class _FoodInputPageState extends State<FoodInputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String _selectedCategory = '野菜・果物';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  String _storageMethod = '冷蔵';
  bool _isStocked = false;
  static const List<String> _categories = ['野菜・果物', '肉類', '魚介類', '乳製品・卵', '主食', '飲料', 'レトルト・缶詰', '調味料', 'その他'];

  @override
  void initState() {
    super.initState();
    final food = widget.existingFood;
    _nameController.text = food?.name ?? widget.initialFoodName;
    _quantityController.text = (food?.quantity ?? widget.initialQuantity).toString();
    _memoController.text = food?.memo ?? widget.initialMemo;
    final String initialCat = food?.category ?? widget.initialCategory;
    _selectedCategory = _categories.contains(initialCat) ? initialCat : 'その他';

    if (food != null) {
      _storageMethod = food.storageMethod;
      _isStocked = food.isStocked;
      try {
        _selectedDate = DateFormat('yyyy/MM/dd').parse(food.expiryDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingFood != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "食材の情報を修正" : "食材の詳細入力"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '食材名 *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '食材名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCategory = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text("期限 (賞味・消費期限)"),
                  subtitle: Text(DateFormat('yyyy年MM月dd日').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today, color: Colors.green),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '数量',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("保管方法", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: ['常温', '冷蔵', '冷凍'].map((method) {
                    return Row(
                      children: [
                        Radio<String>(
                          value: method,
                          groupValue: _storageMethod,
                          onChanged: (value) {
                            setState(() => _storageMethod = value!);
                          },
                        ),
                        Text(method),
                        const SizedBox(width: 12),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Card(
                  color: _isStocked ? Colors.orange[50] : Colors.grey[50],
                  child: SwitchListTile(
                    title: const Text("備蓄用として保存する"),
                    secondary: Icon(
                      _isStocked ? Icons.backpack : Icons.backpack_outlined,
                      color: _isStocked ? Colors.orange : Colors.grey,
                    ),
                    value: _isStocked,
                    onChanged: (bool value) {
                      setState(() => _isStocked = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _memoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'メモ',
                    hintText: '例：早めに使う、何g',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final String uniqueId = isEditing ? widget.existingFood!.id : "id_${DateTime.now().millisecondsSinceEpoch}";
                        final String createdAtStr = isEditing ? widget.existingFood!.createdAt : DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
                        final registeredFood = DetectedFood(
                          id: uniqueId,
                          createdAt: createdAtStr,
                          name: _nameController.text,
                          quantity: int.tryParse(_quantityController.text) ?? 1,
                          category: _selectedCategory,
                          expiryDate: DateFormat('yyyy/MM/dd').format(_selectedDate),
                          storageMethod: _storageMethod,
                          isStocked: _isStocked,
                          memo: _memoController.text,
                        );
                        Navigator.pop(context, registeredFood);
                      }
                    },
                    child: Text(isEditing ? "この内容で修正する" : "この内容で登録する", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}