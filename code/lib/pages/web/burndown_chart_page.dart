import 'package:code/common/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:code/common/theme/app_theme.dart';
import 'package:code/services/task_service.dart';
import 'package:intl/intl.dart';

import 'dart:math';

class BurndownChartPage extends StatefulWidget {
  final String projectId;
  final DateTime queryStartDate;

  const BurndownChartPage({
    super.key,
    required this.projectId,
    required this.queryStartDate,
  });

  @override
  State<BurndownChartPage> createState() => _BurndownChartPageState();
}

class _BurndownChartPageState extends State<BurndownChartPage> {
  // Removida a lista _idealSpots
  List<FlSpot> _actualSpots = [];
  List<FlSpot> _projectionSpots = [];
  bool _isLoading = true;
  String? _errorMessage;

  double _maxX = 5;
  double _maxY = 100;
  List<String> _dateLabels = [];

  late DateTime _selectedQueryStartDate;

  @override
  void initState() {
    super.initState();
    _selectedQueryStartDate = widget.queryStartDate;
    _fetchBurndownData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedQueryStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedQueryStartDate) {
      setState(() {
        _selectedQueryStartDate = picked;
        _fetchBurndownData();
      });
    }
  }

  Future<void> _fetchBurndownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Removido _idealSpots = [];
      _actualSpots = [];
      _projectionSpots = [];
      _dateLabels = [];
      _maxX = 0;
      _maxY = 10;
    });

    try {
      final List<BurndownDataPoint> burndownDataPoints =
          await TaskService.getBurndownData(
              widget.projectId, _selectedQueryStartDate);

      final List<BurndownDataPoint> projectionDataPoints =
          await TaskService.getProjectionData(
              widget.projectId, _selectedQueryStartDate);

      if (!mounted) return;

      // Combine e processe os dados
      List<BurndownDataPoint> combinedData = [];
      if (burndownDataPoints.isNotEmpty) {
        combinedData.addAll(burndownDataPoints);
      }
      if (projectionDataPoints.isNotEmpty) {
        int startDayIndexForProjection = 0;
        if (burndownDataPoints.isNotEmpty) {
          startDayIndexForProjection = burndownDataPoints.last.dayIndex + 1;
        }

        for (var i = 0; i < projectionDataPoints.length; i++) {
          combinedData.add(BurndownDataPoint(
            date: projectionDataPoints[i].date,
            pending: projectionDataPoints[i].pending,
            dayIndex: startDayIndexForProjection + i,
          ));
        }
      }

      combinedData.sort((a, b) => a.date.compareTo(b.date));
      for (int i = 0; i < combinedData.length; i++) {
        combinedData[i] = BurndownDataPoint(
          date: combinedData[i].date,
          pending: combinedData[i].pending,
          dayIndex: i,
        );
      }

      if (combinedData.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Nenhum dado de burndown ou projeção encontrado para o período selecionado.';
        });
        return;
      }

      _actualSpots = burndownDataPoints
          .map((dp) => FlSpot(dp.dayIndex.toDouble(), dp.pending.toDouble()))
          .toList();

      _projectionSpots = projectionDataPoints.map((dp) {
        final matchingCombinedPoint = combinedData.firstWhere(
          (element) => element.date == dp.date,
          orElse: () => dp,
        );
        return FlSpot(
            matchingCombinedPoint.dayIndex.toDouble(), dp.pending.toDouble());
      }).toList();

      _dateLabels = combinedData
          .map((dp) => DateFormat('dd/MM').format(dp.date))
          .toList();

      // Removida a lógica de cálculo de _idealSpots
      double initialWork = burndownDataPoints.isNotEmpty
          ? burndownDataPoints.first.pending.toDouble()
          : 0.0;
      if (initialWork < 0) initialWork = 0;

      int totalDuration = combinedData.length;

      _maxX = (totalDuration - 1).toDouble();
      if (_maxX < 0) _maxX = 0;

      double maxPendingActual = 0;
      if (_actualSpots.isNotEmpty) {
        maxPendingActual = _actualSpots.map((spot) => spot.y).reduce(max);
      }
      double maxPendingProjection = 0;
      if (_projectionSpots.isNotEmpty) {
        maxPendingProjection =
            _projectionSpots.map((spot) => spot.y).reduce(max);
      }

      _maxY = max(initialWork, max(maxPendingActual, maxPendingProjection));
      if (_maxY == 0) _maxY = 10;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _actualSpots = [];
        // Removido _idealSpots = [];
        _projectionSpots = [];
        _maxX = 0;
        _maxY = 10;
        _dateLabels = [];
      });
    }
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 10,
    );
    String text;
    int index = value.toInt();
    if (index >= 0 && index < _dateLabels.length) {
      text = _dateLabels[index];
    } else {
      text = '';
    }
    return SideTitleWidget(
      // axisSide: meta.axisSide,
      space: 4,
      meta: meta,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Burndown Chart'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Progresso do Projeto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Data de Início: ${DateFormat('dd/MM/yyyy').format(_selectedQueryStartDate)}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                  child: Center(
                      child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar gráfico:\n$_errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _fetchBurndownData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              )))
            else if (_actualSpots.isEmpty &&
                _projectionSpots
                    .isEmpty) // Ajustado para verificar apenas real e projeção
              const Expanded(
                  child: Center(
                      child: Text(
                          'Não há dados suficientes para exibir o gráfico no período selecionado.')))
            else
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: _bottomTitleWidgets,
                          reservedSize: 30,
                          interval: (_maxX / 5).ceilToDouble() == 0
                              ? 1
                              : (_maxX / 5).ceilToDouble(),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: _maxX,
                    minY: 0,
                    maxY: _maxY,
                    lineTouchData: LineTouchData(touchTooltipData:
                        LineTouchTooltipData(getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String yValue = spot.y.toStringAsFixed(1);
                        String xLabel = "Dia ${spot.x.toInt()}";
                        if (spot.x.toInt() >= 0 &&
                            spot.x.toInt() < _dateLabels.length) {
                          xLabel = _dateLabels[spot.x.toInt()];
                        }

                        final textStyle = TextStyle(
                          color: spot.bar.gradient?.colors.first ??
                              spot.bar.color ??
                              Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        );
                        return LineTooltipItem('$xLabel\n', textStyle,
                            children: [
                              TextSpan(
                                text: yValue,
                                style: TextStyle(
                                  color: spot.bar.gradient?.colors.first ??
                                      spot.bar.color ??
                                      Colors.blueGrey,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: spot.bar.color ==
                                        Colors.red.withOpacity(0.8)
                                    ? ' (Real)'
                                    : ' (Projeção)', // Ajustado para remover a linha ideal
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              )
                            ]);
                      }).toList();
                    })),
                    lineBarsData: [
                      // Removida a LineChartBarData para a linha ideal
                      LineChartBarData(
                        spots: _actualSpots,
                        isCurved: true,
                        color: Colors.red.withOpacity(0.8),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: _projectionSpots,
                        isCurved: true,
                        color: Colors.green.withOpacity(0.8),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Removida a entrada da legenda para a linha ideal
                Container(
                    width: 16, height: 16, color: Colors.red.withOpacity(0.8)),
                const SizedBox(width: 8),
                const Text('Real (Pendentes)'),
                const SizedBox(width: 24),
                Container(
                    width: 16,
                    height: 16,
                    color: Colors.green.withOpacity(0.8)),
                const SizedBox(width: 8),
                const Text('Projeção'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
