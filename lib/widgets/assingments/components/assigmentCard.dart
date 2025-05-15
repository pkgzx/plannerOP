import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/foodUtils.dart';
import 'package:plannerop/widgets/assingments/components/showCompletionDialog.dart';
import 'package:provider/provider.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final Function(BuildContext, Assignment) onTap;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final areasProvider = Provider.of<AreasProvider>(context, listen: false);
    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    List<String> foods =
        FoodUtils.determinateFoods(assignment.time, assignment.endTime);

    // Verificar si hay comidas válidas y si todos los trabajadores han recibido alimentación
    bool validFood = foods.isNotEmpty && foods[0] != 'Sin alimentación';
    bool allWorkersReceived = false;

    if (validFood) {
      List<int> workerIds = assignment.workers.map((w) => w.id).toList();
      allWorkersReceived = feedingProvider.areAllWorkersMarked(
          assignment.id ?? 0, workerIds, foods[0]);
    }

    // Mostrar chip solo si hay comida válida y NO todos han recibido
    bool shouldShowFoodChips = validFood && !allWorkersReceived;

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
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFF3182CE),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildTaskInfo(areasProvider),
              Container(
                height: 1,
                color: const Color(0xFFEDF2F7),
                margin: const EdgeInsets.only(bottom: 6),
              ),
              _buildFooterInfo(context, assignmentsProvider),
              if (shouldShowFoodChips) _buildFoodChips(foods),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfo(AreasProvider areasProvider) {
    return Expanded(
      child: Column(
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
                  areasProvider.getAreaById(assignment.areaId)?.name ?? "",
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
      ),
    );
  }

  Widget _buildFooterInfo(BuildContext context, AssignmentsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 10,
              color: const Color(0xFF718096).withOpacity(0.8),
            ),
            const SizedBox(width: 3),
            Text(
              DateFormat('dd/MM/yy').format(assignment.date),
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF718096).withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
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
          ],
        ),
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF38A169),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38A169).withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showCompletionDialog(
                  context: context, assignment: assignment, provider: provider),
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodChips(List<String> foods) {
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (foods.contains('Desayuno'))
                _buildFoodChip(
                    Icons.free_breakfast, "Desayuno", Colors.orange[700]!),
              if (foods.contains('Almuerzo'))
                _buildFoodChip(
                    Icons.restaurant, "Almuerzo", Colors.green[700]!),
              if (foods.contains('Cena'))
                _buildFoodChip(Icons.dinner_dining, "Cena", Colors.blue[700]!),
              if (foods.contains('Media noche'))
                _buildFoodChip(
                    Icons.nightlight_round, "Media noche", Colors.indigo[700]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodChip(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Tooltip(
        message: "",
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Text(
                label.split(' ')[0], // Solo primera palabra
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
