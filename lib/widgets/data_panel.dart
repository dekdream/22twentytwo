import 'package:flutter/material.dart';

class DataPanel extends StatelessWidget {
  const DataPanel({
    super.key,
    required this.future,
    required this.columns,
    required this.rowBuilder,
    this.emptyMessage = 'ยังไม่มีข้อมูล',
  });

  final Future<List<Map<String, dynamic>>> future;
  final List<DataColumn> columns;
  final List<DataCell> Function(Map<String, dynamic> row) rowBuilder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return Center(
            child: Text(emptyMessage, style: const TextStyle(color: Color(0xff999999))),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final row = rows[index];
            final cells = rowBuilder(row);
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('รายละเอียด'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < cells.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DefaultTextStyle.merge(
                                    style: const TextStyle(
                                      color: Color(0xffd4537e),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    child: columns[i].label,
                                  ),
                                  const SizedBox(height: 3),
                                  cells[i].child,
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('ปิด'))],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xfffff0f5), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.list_alt_outlined, color: Color(0xffd4537e))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (cells.isNotEmpty) cells.first.child, if (cells.length > 1) DefaultTextStyle.merge(style: const TextStyle(color: Color(0xff9693a8), fontSize: 12), child: cells[1].child)])),
                    if (cells.length > 2) cells.last.child,
                  ]),
                ),
              ),
            );
          },
        );

        final table = DataTable(
          columnSpacing: compact ? 14 : 32,
          horizontalMargin: compact ? 10 : 24,
          headingRowHeight: compact ? 38 : 56,
          dataRowMinHeight: compact ? 38 : 48,
          dataRowMaxHeight: compact ? 48 : 56,
          headingRowColor: WidgetStateProperty.all(const Color(0xfffce4ec)),
          headingTextStyle: TextStyle(
            color: const Color(0xff993556),
            fontWeight: FontWeight.w600,
            fontSize: compact ? 11 : 14,
          ),
          dataTextStyle: TextStyle(
            color: const Color(0xff1a1a1a),
            fontSize: compact ? 11 : 14,
          ),
          columns: columns,
          rows: [for (final row in rows) DataRow(cells: rowBuilder(row))],
        );

        return LayoutBuilder(
          builder: (context, constraints) => Card(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: compact
                  ? SizedBox(
                      width: constraints.maxWidth,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topLeft,
                        child: table,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: SingleChildScrollView(child: table),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
