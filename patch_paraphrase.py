import re

with open(r'lib\features\paraphrase\paraphrase_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add topup prices to variables inside _showTokenDialog
search_1 = r"""  void _showTokenDialog\(\) \{
    final authProvider = context\.read<AuthProvider>\(\);
    final tokenBalance = authProvider\.tokenBalance;

    int selectedCoins = 50;"""

replace_1 = """  void _showTokenDialog() {
    final authProvider = context.read<AuthProvider>();
    final tokenBalance = authProvider.tokenBalance;
    final minCoins = authProvider.topupMinCoins;
    final pricePerCoin = authProvider.topupPricePerCoin;
    final priceLabel = pricePerCoin % 1 == 0
        ? pricePerCoin.toInt().toString()
        : pricePerCoin.toStringAsFixed(2);

    int selectedCoins = minCoins > 50 ? minCoins : 50;"""

content = re.sub(search_1, replace_1, content)

# 2. Remove inal pricePerCoin = 1000;
search_2 = r"""            final bottomPadding = MediaQuery\.of\(context\)\.viewInsets\.bottom;
            final pricePerCoin = 1000;
            final totalPrice = selectedCoins \* pricePerCoin;"""

replace_2 = """            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            final totalPrice = selectedCoins * pricePerCoin;"""

content = re.sub(search_2, replace_2, content)

# 3. Fix price label display
search_3 = r"""Harga: Rp \ / token"""
replace_3 = """Harga: Rp  / token"""
content = re.sub(search_3, replace_3, content)

# 4. Fix preset amount buttons array
search_4 = r"""                        children: \[10, 50, 100, 500, 1000\]\.map\(\(amount\) \{"""
replace_4 = """                        children: [10, 50, 100, 500, 1000].where((amount) => amount >= minCoins).map((amount) {"""
content = re.sub(search_4, replace_4, content)

# 5. Fix .toList() which might be at the end of map
search_5 = r"""                          \}\)\.toList\(\),
                        \),"""
replace_5 = """                          }).toList(),
                        ),"""
content = re.sub(search_5, replace_5, content)
# wait, .toList() is already there, I just changed the array before .map

# 6. Fix min input text
search_6 = r"""labelText: 'Jumlah Token \(Min\. 10\)',"""
replace_6 = """labelText: 'Jumlah Token (Min. )',"""
content = re.sub(search_6, replace_6, content)

# 7. Fix minimum button press
search_7 = r"""                          onPressed: selectedCoins < 10
                              \? null"""
replace_7 = """                          onPressed: selectedCoins < minCoins
                              ? null"""
content = re.sub(search_7, replace_7, content)

with open(r'lib\features\paraphrase\paraphrase_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Paraphrase patched safely")
