import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/utils/foodUtils.dart';
import 'package:provider/provider.dart';

class UnifiedAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final Function(BuildContext, Assignment) onTap;

  // Customization parameters
  final Color statusColor;
  final String statusText;
  final bool showCompletionDate;
  final bool showFoodInfo;
  final Widget? actionButton;

  const UnifiedAssignmentCard({
    Key? key,
    required this.assignment,
    required this.onTap,
    required this.statusColor,
    required this.statusText,
    this.showCompletionDate = false,
    this.showFoodInfo = false,
    this.actionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final areasProvider = Provider.of<AreasProvider>(context, listen: false);

    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        intensity: 0.5,
        color: Colors.white,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        lightSource: LightSource.topLeft,
        shadowDarkColorEmboss: Colors.grey.withOpacity(0.2),
        shadowLightColorEmboss: Colors.white,
      ),
      child: InkWell(
        onTap: () => onTap(context, assignment),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              _buildStatusIndicator(),

              const SizedBox(height: 8),

              // Task info
              _buildTaskInfo(areasProvider),

              // Completion date (for completed assignments)
              if (showCompletionDate && assignment.endDate != null)
                _buildCompletionDate(),

              // Separator
              Container(
                height: 1,
                color: const Color(0xFFEDF2F7),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),

              // Footer with info and action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFooterInfo(),
                  if (actionButton != null) actionButton!,
                ],
              ),

              // Food chips if applicable
              if (showFoodInfo) _buildFoodChips(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo(AreasProvider areasProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assignment.task,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: Color(0xFF718096),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                assignment.area,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionDate() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 14,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd/MM/yyyy')
                .format(assignment.endDate ?? DateTime.now()),
            style: TextStyle(
              fontSize: 13,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Row(
      children: [
        // Worker count
        Icon(
          Icons.people_outline,
          size: 10,
          color: const Color(0xFF718096).withOpacity(0.8),
        ),
        const SizedBox(width: 3),
        Text(
          "${assignment.workers.length}",
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFF718096).withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),

        // Time
        Icon(
          Icons.access_time,
          size: 10,
          color: const Color(0xFF718096).withOpacity(0.8),
        ),
        const SizedBox(width: 3),
        Text(
          assignment.time,
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFF718096).withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodChips() {
    // Get foods based on assignment times
    List<String> foods =
        FoodUtils.determinateFoods(assignment.time, assignment.endTime);

    if (foods.isEmpty || foods.contains('Sin alimentación')) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        children: foods.map((food) {
          IconData icon;
          Color color;

          switch (food) {
            case 'Desayuno':
              icon = Icons.free_breakfast;
              color = Colors.orange;
              break;
            case 'Almuerzo':
              icon = Icons.restaurant;
              color = Colors.green;
              break;
            case 'Cena':
              icon = Icons.dinner_dining;
              color = Colors.blue;
              break;
            default:
              icon = Icons.fastfood;
              color = Colors.purple;
          }

          return Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.zero,
            backgroundColor: color.withOpacity(0.1),
            avatar: Icon(icon, size: 12, color: color),
            label: Text(
              food,
              style: TextStyle(fontSize: 10, color: color),
            ),
          );
        }).toList(),
      ),
    );
  }
}
