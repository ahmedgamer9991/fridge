import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/widgets/widgets.dart';
import 'package:fridge/utils/error_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data
  final String _fridgeName = 'My Home Fridge';

  Map<String, dynamic>? _userProfile;

  // Toggle states
  bool _expiryAlerts = true;
  bool _spoilageAlerts = false;
  bool _groceryReminders = true;

  // Slider value
  double _notifyBeforeExpiry = 3.0;

  // Restocking threshold
  int _restockingThreshold = 2;
  final TextEditingController _restockingController = TextEditingController();

  // Language
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];

  // Fridge name
  final TextEditingController _fridgeNameController = TextEditingController();

  // Focus Node
  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();

  Future<void> _loadUserProfile() async {
    try {
      final profile = await FirebaseServices().getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
      await _loadLocalSettings();
    } catch (error) {
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, ErrorUtils.parseError(error));
      }
    }
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyBeforeExpiry = prefs.getDouble('notifyBeforeExpiry') ?? 3.0;
    });
  }

  Future<void> _saveNotificationSetting(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('notifyBeforeExpiry', value);
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _restockingController.text = '$_restockingThreshold';
    _fridgeNameController.text = _fridgeName;
  }

  @override
  void dispose() {
    _restockingController.dispose();
    _fridgeNameController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Profile',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              UserProfileCard(userProfile: _userProfile),

              const SizedBox(height: 24),

              // Notification Settings
              ProfileSection(
                title: 'Notification Settings',
                children: [
                  ProfileToggleTile(
                    title: 'Expiry Alerts',
                    description:
                        'Receive notifications when items are nearing their expiry date.',
                    value: _expiryAlerts,
                    onChanged: (value) => setState(() => _expiryAlerts = value),
                  ),
                  const Divider(thickness: .5, indent: 15, endIndent: 15),
                  ProfileToggleTile(
                    title: 'Spoilage Alerts',
                    description:
                        'Get alerts for items likely to spoil soon, even before expiry.',
                    value: _spoilageAlerts,
                    onChanged: (value) =>
                        setState(() => _spoilageAlerts = value),
                  ),
                  const Divider(thickness: .5, indent: 15, endIndent: 15),
                  ProfileToggleTile(
                    title: 'Grocery Reminders',
                    description:
                        'Be reminded to buy low-stock items for your favorite meals.',
                    value: _groceryReminders,
                    onChanged: (value) =>
                        setState(() => _groceryReminders = value),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Alert Preferences
              ProfileSection(
                title: 'Alert Preferences',
                children: [
                  ProfileSliderTile(
                    title: 'Notify Before Expiry',
                    description: 'Days before expiry to receive an alert.',
                    value: _notifyBeforeExpiry,
                    min: 1,
                    max: 7,
                    unit: 'days',
                    onChanged: (value) {
                      setState(() => _notifyBeforeExpiry = value);
                      _saveNotificationSetting(value);
                    },
                  ),
                  const SizedBox(height: 5),
                  const Divider(thickness: .5, indent: 15, endIndent: 15),
                  ProfileTextFieldTile(
                    title: 'Restocking Threshold',
                    description:
                        'Alert when favorite meal ingredients are less than N items.',
                    controller: _restockingController,
                    unit: 'items',
                    focusNode: _focusNode1,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final num = int.tryParse(value);
                        if (num != null) {
                          setState(() => _restockingThreshold = num);
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Preferences
              ProfileSection(
                title: 'Account Preferences',
                children: [
                  const SizedBox(height: 4), // Added some padding to match look
                  ProfileDropdownTile(
                    title: 'Language',
                    description: 'Select your preferred language for the app.',
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (value) =>
                        setState(() => _selectedLanguage = value!),
                  ),
                  const Divider(thickness: .5, indent: 15, endIndent: 15),
                  ProfileTextFieldTile(
                    title: 'Fridge Name',
                    description:
                        'Customize the name displayed for your fridge.',
                    controller: _fridgeNameController,
                    focusNode: _focusNode2,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseServices().signOut();
                    } catch (error) {
                      if (context.mounted) {
                        ErrorUtils.showErrorSnackBar(
                          context,
                          ErrorUtils.parseError(error),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusSpoiled,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
