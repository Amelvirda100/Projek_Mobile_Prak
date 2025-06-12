import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/pages/add_page.dart';
import 'package:budgetlisting/pages/detail_page.dart';
import 'package:budgetlisting/pages/login_register_page.dart';
import 'package:budgetlisting/models/transaction_model.dart';
import 'package:budgetlisting/services/transaction_service.dart';
import 'package:budgetlisting/pages/location_page.dart';
import 'package:budgetlisting/pages/profil_page.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> transactions = [];
  List<Transaction> filteredTransactions = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  String selectedFilter = 'all';
  String selectedCurrency = 'IDR';

  final mainColor = const Color.fromRGBO(97, 126, 140, 1.0);

  final Map<String, String> currencySymbols = {
    'USD': 'AS\$',
    'JPY': '¥',
    'EUR': '€',
    'SGD': 'S\$',
    'IDR': 'Rp',
  };

  final Map<String, double> currencyRates = {
    'USD': 16200.0,
    'JPY': 112.0,
    'EUR': 18500.0,
    'SGD': 12600.0,
    'IDR': 1.0,
  };

  @override
  void initState() {
    super.initState();
      super.didChangeDependencies();
      fetchTransactions();
  }

  // Tambahkan ini untuk refresh otomatis
  void refreshData() {
    if (mounted) {
      setState(() {
        fetchTransactions();
      });
    }
  }

  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      logout(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> fetchTransactions() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final hasConnection = await isConnected();
    if (!hasConnection) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Tidak Ada Koneksi Internet"),
          content: const Text("Periksa koneksi Wi-Fi atau data seluler Anda."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      setState(() => isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginRegisterPage()),
      );
      return;
    }

    try {
      final response = await TransactionAPI.getTransactions(token);
      if (response['transactions'] != null) {
        transactions = (response['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
        applyFilter();
      } else if (response['message']?.toLowerCase().contains('expired') == true) {
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginRegisterPage()),
        );
      }
    } catch (e) {
      debugPrint("Gagal fetch transaksi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data transaksi.')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void applyFilter() {
    setState(() {
      if (selectedFilter == 'income') {
        filteredTransactions = transactions.where((t) => t.type == 'income').toList();
      } else if (selectedFilter == 'expense') {
        filteredTransactions = transactions.where((t) => t.type == 'expense').toList();
      } else {
        filteredTransactions = transactions;
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginRegisterPage()));
  }

  Future<void> navigateToAddPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    ).then((_) {
      // Selalu refresh saat kembali dari Add Page
      refreshData();

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil ditambahkan!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  double calculateTotal(String type) {
    final rate = currencyRates[selectedCurrency]!;
    return transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0) * (t.currencyRate ?? 1) / rate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: const Text(
          'Dashboard Keuangan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: mainColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCurrency,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                underline: const SizedBox(),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                items: currencySymbols.keys.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.blueGrey[700], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          c,
                          style: TextStyle(color: Colors.blueGrey[900]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedCurrency = val);
                  }
                },
              ),
            ),
          ),
        ],
      )
          : null, // ✅ AppBar hanya di tab 0
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          buildHomePageContent(),
          const ProfilePage(),
          const LocationPage(),
          Container(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: mainColor,
        icon: const Icon(Icons.attach_money, color: Colors.white),
        label: const Text(
          "Tambah Transaksi",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: navigateToAddPage,
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Lokasi'),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: 'Keluar'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: mainColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildHomePageContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return const Center(child: Text("Belum ada transaksi."));
    }

    final income = calculateTotal('income');
    final expense = calculateTotal('expense');
    final total = income - expense;
    final percent = income + expense == 0 ? 0.5 : income / (income + expense);

    final currencySymbol = currencySymbols[selectedCurrency] ?? 'Rp';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 50,
                    lineWidth: 8,
                    percent: percent,
                    center: Text("${(percent * 100).toStringAsFixed(0)}%"),
                    progressColor: mainColor,
                    backgroundColor: Colors.red[200]!,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Saldo Anda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          "$currencySymbol ${NumberFormat('#,##0.00').format(total)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: total >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Pemasukan: $currencySymbol ${income.toStringAsFixed(2)}\nPengeluaran: $currencySymbol ${expense.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text("Filter: "),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Semua"),
                  selected: selectedFilter == 'all',
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = 'all';
                      applyFilter();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Pemasukan"),
                  selected: selectedFilter == 'income',
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = 'income';
                      applyFilter();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Pengeluaran"),
                  selected: selectedFilter == 'expense',
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = 'expense';
                      applyFilter();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: filteredTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];
                final amount = t.amount ?? 0;
                final rate = t.currencyRate ?? 1.0;
                final toIDR = amount * rate;
                final toSelected = toIDR / currencyRates[selectedCurrency]!;
                final isIncome = t.type == 'income';

                final symbol = currencySymbols[selectedCurrency]!;
                final originalSymbol = currencySymbols[t.currencyCode ?? 'IDR'] ?? '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? mainColor : Colors.red[300],
                      child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white),
                    ),
                    title: Text(t.category ?? '(Tanpa Kategori)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${isIncome ? 'Pemasukan' : 'Pengeluaran'} • ${t.date}"),
                        Text("$originalSymbol ${amount.toStringAsFixed(0)} → $symbol ${toSelected.toStringAsFixed(2)}"),
                        if (t.note != null && t.note!.isNotEmpty)
                          Text(t.note!, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(transactionId: t.id!),
                        ),
                      ).then((value) {
                        if (value == true) {
                          fetchTransactions(); // Refresh saat kembali
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}