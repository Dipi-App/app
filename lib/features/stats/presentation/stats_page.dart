import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آمار')),
      body: const EmptyState(
        title: 'آماری برای نمایش نیست',
        message: 'پس از ثبت روزکار و پرداخت‌ها، مجموع روزها، ساعت‌ها، '
            'درآمد و مانده هر کارفرما را با نمودار می‌بینید.',
      ),
    );
  }
}
