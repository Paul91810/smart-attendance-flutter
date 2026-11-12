import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../domain/entities/employee.dart';
import '../widgets/admin_employee_detail_pane.dart';

class AdminEmployeeDetailPage extends StatelessWidget {
  final Employee employee;

  const AdminEmployeeDetailPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 720 : double.infinity,
              ),
              child: AdminEmployeeDetailPane(employee: employee),
            ),
          );
        },
      ),
    );
  }
}
