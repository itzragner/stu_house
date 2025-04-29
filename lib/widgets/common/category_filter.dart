import 'package:flutter/material.dart';
import '../../config/themes.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilter({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: _getCategoryIcon(category, isSelected),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getCategoryIcon(String category, bool isSelected) {
    IconData iconData;
    Color iconColor = isSelected ? AppTheme.primaryColor : Colors.grey[600]!;

    switch (category.toLowerCase()) {
      case 'tous':
        iconData = Icons.home;
        break;
      case 'appartement':
        iconData = Icons.apartment;
        break;
      case 'studio':
        iconData = Icons.single_bed;
        break;
      case 'chambre':
        iconData = Icons.hotel;
        break;
      case 'colocation':
        iconData = Icons.people;
        break;
      case 'maison':
        iconData = Icons.house;
        break;
      default:
        iconData = Icons.home;
    }

    return Icon(
      iconData,
      size: 24,
      color: iconColor,
    );
  }
}