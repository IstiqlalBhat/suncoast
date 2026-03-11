import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../shared/models/session_summary_model.dart';

class SummaryExport {
  const SummaryExport._();

  /// Build a Markdown string from the summary.
  static String toMarkdown({
    required SessionSummaryModel summary,
    required String activityTitle,
    int? durationSeconds,
  }) {
    final buf = StringBuffer();

    buf.writeln('# Session Summary');
    buf.writeln();
    buf.writeln('**Activity:** $activityTitle');
    if (durationSeconds != null) {
      buf.writeln('**Duration:** ${_fmtDuration(durationSeconds)}');
    }
    if (summary.createdAt != null) {
      buf.writeln(
        '**Date:** ${DateFormat.yMMMMd().format(summary.createdAt!)}',
      );
    }
    buf.writeln();

    // Overview
    if (summary.observationSummary.trim().isNotEmpty) {
      buf.writeln('## Overview');
      buf.writeln();
      buf.writeln(summary.observationSummary.trim());
      buf.writeln();
    }

    // Key Observations
    if (summary.keyObservations.isNotEmpty) {
      buf.writeln('## Key Observations');
      buf.writeln();
      for (final obs in summary.keyObservations) {
        buf.writeln('- $obs');
      }
      buf.writeln();
    }

    // Actions Taken
    final actions = _actionLines(summary);
    if (actions.isNotEmpty) {
      buf.writeln('## Actions Taken');
      buf.writeln();
      for (final a in actions) {
        buf.writeln('- ${a.label} _(${a.status})_');
      }
      buf.writeln();
    }

    // Follow-Ups
    if (summary.followUps.isNotEmpty) {
      buf.writeln('## Follow-Ups');
      buf.writeln();
      for (final fu in summary.followUps) {
        final due = fu.dueDate != null
            ? ' — due ${DateFormat.yMMMd().format(fu.dueDate!)}'
            : '';
        buf.writeln('- **[${fu.priority}]** ${fu.description}$due');
      }
      buf.writeln();
    }

    return buf.toString();
  }

  /// Share a Markdown (.md) file via the system share sheet.
  static Future<void> shareAsMarkdown({
    required SessionSummaryModel summary,
    required String activityTitle,
    int? durationSeconds,
  }) async {
    final md = toMarkdown(
      summary: summary,
      activityTitle: activityTitle,
      durationSeconds: durationSeconds,
    );

    final dir = await getTemporaryDirectory();
    final fileName = _safeFileName(activityTitle);
    final file = File('${dir.path}/${fileName}_summary.md');
    await file.writeAsString(md);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '$activityTitle — Session Summary',
      ),
    );
  }

  /// Share a PDF file via the system share sheet.
  static Future<void> shareAsPdf({
    required SessionSummaryModel summary,
    required String activityTitle,
    int? durationSeconds,
  }) async {
    final bytes = await _buildPdf(
      summary: summary,
      activityTitle: activityTitle,
      durationSeconds: durationSeconds,
    );

    final dir = await getTemporaryDirectory();
    final fileName = _safeFileName(activityTitle);
    final file = File('${dir.path}/${fileName}_summary.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '$activityTitle — Session Summary',
      ),
    );
  }

  // ── PDF Generation ────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdf({
    required SessionSummaryModel summary,
    required String activityTitle,
    int? durationSeconds,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Title
          widgets.add(
            pw.Text(
              'Session Summary',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          // Metadata
          widgets.add(
            pw.Text(
              'Activity: $activityTitle',
              style: const pw.TextStyle(fontSize: 14),
            ),
          );
          if (durationSeconds != null) {
            widgets.add(
              pw.Text(
                'Duration: ${_fmtDuration(durationSeconds)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            );
          }
          if (summary.createdAt != null) {
            widgets.add(
              pw.Text(
                'Date: ${DateFormat.yMMMMd().format(summary.createdAt!)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            );
          }
          widgets.add(pw.SizedBox(height: 20));
          widgets.add(pw.Divider());
          widgets.add(pw.SizedBox(height: 12));

          // Overview
          if (summary.observationSummary.trim().isNotEmpty) {
            widgets.add(_pdfSection('Overview'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              pw.Text(
                summary.observationSummary.trim(),
                style: const pw.TextStyle(fontSize: 12),
              ),
            );
            widgets.add(pw.SizedBox(height: 16));
          }

          // Key Observations
          if (summary.keyObservations.isNotEmpty) {
            widgets.add(_pdfSection('Key Observations'));
            widgets.add(pw.SizedBox(height: 6));
            for (final obs in summary.keyObservations) {
              widgets.add(_pdfBullet(obs));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // Actions
          final actions = _actionLines(summary);
          if (actions.isNotEmpty) {
            widgets.add(_pdfSection('Actions Taken'));
            widgets.add(pw.SizedBox(height: 6));
            for (final a in actions) {
              widgets.add(_pdfBullet('${a.label} (${a.status})'));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // Follow-Ups
          if (summary.followUps.isNotEmpty) {
            widgets.add(_pdfSection('Follow-Ups'));
            widgets.add(pw.SizedBox(height: 6));
            for (final fu in summary.followUps) {
              final due = fu.dueDate != null
                  ? ' — due ${DateFormat.yMMMd().format(fu.dueDate!)}'
                  : '';
              widgets.add(
                _pdfBullet('[${fu.priority}] ${fu.description}$due'),
              );
            }
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfSection(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _pdfBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: const pw.TextStyle(fontSize: 12)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static List<_ActionLine> _actionLines(SessionSummaryModel summary) {
    if (summary.actionStatuses.isNotEmpty) {
      return summary.actionStatuses
          .map(
            (item) => _ActionLine(
              label: (item['label'] ?? item['description'] ?? 'Action')
                  .toString(),
              status: (item['status'] ?? 'completed').toString(),
            ),
          )
          .toList();
    }
    return summary.actionsTaken
        .map((a) => _ActionLine(label: a, status: 'completed'))
        .toList();
  }

  static String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  static String _safeFileName(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class _ActionLine {
  final String label;
  final String status;
  const _ActionLine({required this.label, required this.status});
}
