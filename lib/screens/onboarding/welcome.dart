import 'package:flutter/material.dart';
import 'package:Eyeventory/utils/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App Header
              Column(
                children: [
                  SizedBox(height: 30),
                  Text(
                    'Eyeventory',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our Motto',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorsSecondary,
                      fontWeight: .w400,
                    ),
                  ),
                ],
              ),

              // User Type Cards
              Column(
                children: [
                  _buildUserTypeCard(
                    icon: Icons.home_outlined,
                    title: "I'm a Home User",
                    description:
                        "Manage groceries, recipes & meal plans for your home.",
                    isSelected: selectedUserType == 'home',
                    onTap: () => setState(() => selectedUserType = 'home'),
                  ),
                  const SizedBox(height: 16),
                  _buildUserTypeCard(
                    icon: Icons.storefront_outlined,
                    title: "I'm a Store Manager",
                    description:
                        "Optimize inventory, reduce waste & track stock for your store.",
                    isSelected: selectedUserType == 'store',
                    onTap: () => setState(() => selectedUserType = 'store'),
                  ),
                ],
              ),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedUserType != null
                      ? () {
                          Navigator.pushNamed(context, '/login');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorsPrimary,
                    foregroundColor: Colors.black,
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
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? colorsPrimary : colorsBorder,
            width: 1.7,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: colorsPrimary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colorsSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
