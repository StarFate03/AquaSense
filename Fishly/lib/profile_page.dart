import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = ' ';
  String role = ' ';
  String email = ' ';
  String phone = ' ';
  String unit = 'Metric'; // Default to Metric

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnit();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('profile_name') ?? name;
      role = prefs.getString('profile_role') ?? role;
      email = prefs.getString('profile_email') ?? email;
      phone = prefs.getString('profile_phone') ?? phone;
    });
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      unit = prefs.getString('unit_of_measurement') ?? 'Metric';
    });
  }

  Future<void> _saveUnit(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit_of_measurement', value);
    setState(() {
      unit = value;
    });
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Unit of Measurement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Metric (°C, %)'),
                value: 'Metric',
                groupValue: unit,
                onChanged: (value) {
                  if (value != null) {
                    _saveUnit(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Imperial (°F, in)'),
                value: 'Imperial',
                groupValue: unit,
                onChanged: (value) {
                  if (value != null) {
                    _saveUnit(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_role', role);
    await prefs.setString('profile_email', email);
    await prefs.setString('profile_phone', phone);
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: name);
    final roleController = TextEditingController(text: role);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Personal Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  name = nameController.text;
                  role = roleController.text;
                  email = emailController.text;
                  phone = phoneController.text;
                });
                await _saveProfile();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode
        ? const Color(0xFF0d2b36)
        : const Color(0xFFF6F8FA);
    final cardColor = isDarkMode ? const Color(0xFF1a3442) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Avatar with Camera Icon
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: const AssetImage(
                        'assets/images/Fishly_icon.png',
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Personal Information Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            onPressed: _showEditDialog,
                            tooltip: 'Edit',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProfileInfoRow(
                        label: 'Name',
                        value: name,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      _ProfileInfoRow(
                        label: 'Role',
                        value: role,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      _ProfileInfoRow(
                        label: 'Email',
                        value: email,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      _ProfileInfoRow(
                        label: 'Phone',
                        value: phone,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Monitoring Responsibilities Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Responsibilities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Assigned Ponds',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final chipBg = isDark
                                  ? const Color(0xFF1a3442)
                                  : Colors.blue.shade50;
                              final chipText = isDark
                                  ? Colors.white
                                  : Colors.black;
                              return Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      'Pond A',
                                      style: TextStyle(color: chipText),
                                    ),
                                    backgroundColor: chipBg,
                                  ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text(
                                      'Pond B',
                                      style: TextStyle(color: chipText),
                                    ),
                                    backgroundColor: chipBg,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+3',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Access Level',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Administrator',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Preferences Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: true,
                        onChanged: (v) {},
                        title: Text(
                          'Notification Alerts',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: false,
                        onChanged: (v) {},
                        title: Text(
                          'Critical Alerts Only',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        title: Text(
                          'Units of Measurement',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        trailing: Text(
                          unit,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: _showUnitDialog,
                      ),
                      SwitchListTile(
                        value: themeProvider.isDarkMode,
                        onChanged: (v) => themeProvider.toggleTheme(v),
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        title: Text(
                          'Language',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        trailing: Text(
                          'English',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {},
                      ),
                      SwitchListTile(
                        value: true,
                        onChanged: (v) {},
                        title: Text(
                          'Data Sync',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Notes & SOPs Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Responsible for daily water quality checks on all assigned ponds. Must report any pH levels outside 6.5-8.5 range immediately. Weekly maintenance of oxygen sensors required.',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subTextColor;
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subTextColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: subTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w400, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
