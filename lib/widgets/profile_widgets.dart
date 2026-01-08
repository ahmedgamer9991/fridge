import 'package:flutter/material.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/widgets/widgets.dart';

class UserProfileCard extends StatelessWidget {
  final Map<String, dynamic>? userProfile;

  const UserProfileCard({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: colorsBorder, width: .5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    child: Image.asset(
                      'john_doe.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 48,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userProfile?["name"] ?? "Loading...",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?['email'] ?? 'none',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?['role'] ?? "none role",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: .5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class ProfileToggleTile extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileToggleTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: colorsPrimary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: colorsBorder,
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return Colors.transparent;
        }),
      ),
    );
  }
}

class ProfileSliderTile extends StatelessWidget {
  final String title;
  final String description;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const ProfileSliderTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 3,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                '${value.toInt()} $unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorsPrimary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4.0,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).toInt(),
                  label: '${value.toInt()} $unit',
                  activeColor: colorsPrimary,
                  inactiveColor: colorsBorder,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileTextFieldTile extends StatelessWidget {
  final String title;
  final String description;
  final TextEditingController controller;
  final String? unit;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const ProfileTextFieldTile({
    super.key,
    required this.title,
    required this.description,
    required this.controller,
    this.unit,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    if (unit != null) {
      return ListTile(
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: SizedBox(
          width: 100,
          child: AppTextField(
            onTapOutside: (event) => focusNode?.unfocus(),
            focusNode: focusNode ?? FocusNode(),
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            hintText: '',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            AppTextField(
              onTapOutside: (event) => focusNode?.unfocus(),
              focusNode: focusNode ?? FocusNode(),
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              hintText: '',
            ),
          ],
        ),
      );
    }
  }
}

class ProfileDropdownTile extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const ProfileDropdownTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      trailing: SizedBox(
        width: 140,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: textBorder,
            enabledBorder: textBorder,
            focusedBorder: textBorder,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ),
    );
  }
}
