import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/asset.dart';

class PortfolioChart extends StatelessWidget {
  final List<Asset> assets;

  const PortfolioChart({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    // 자산 가치가 0이면 차트를 그리지 않음
    if (assets.isEmpty || assets.every((a) => a.totalValue == 0)) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("데이터를 불러오는 중이거나 자산이 없습니다.")),
      );
    }

    return SizedBox(
      height: 250, // 차트 높이
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _getSections(assets),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(List<Asset> assets) {
    final total = assets.fold(0.0, (sum, item) => sum + item.totalValue);

    // 색상 팔레트
    final colors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.redAccent,
      Colors.teal,
    ];

    return List.generate(assets.length, (index) {
      final asset = assets[index];
      final percentage = (asset.totalValue / total) * 100;
      final isLarge = percentage > 10; // 10% 이상이면 텍스트를 좀 더 크게

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: asset.totalValue,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isLarge ? 60 : 50,
        titleStyle: TextStyle(
          fontSize: isLarge ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
