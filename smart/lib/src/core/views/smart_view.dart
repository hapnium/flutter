import 'package:meta/meta.dart';
import 'package:flutter/widgets.dart' show StatelessWidget, Widget, BuildContext;
import 'package:smart/responsive.dart';

import '../di/smart_di.dart';
import '../state/smart_controller.dart';

abstract class SmartView<T extends SmartController> extends StatelessWidget {
  SmartView({super.key});

  final String? tag = null;
  T get controller => SmartDI.find<T>();

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return create(context, ResponsiveUtil(context, config: SmartDI.responsive));
  }

  @mustBeOverridden
  Widget create(BuildContext context, ResponsiveUtil responsive);
}