import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';

/// AI 안전 진단 보고서를 PDF로 생성하고 미리보기/저장하는 서비스
class ReportService {
  // 현재 시간 포맷
  static String get _now => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  static String get _dateOnly => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// PDF 보고서를 생성하고 미리보기 화면을 띄움
  static Future<void> generateAndPreview(BuildContext context, List<Device> devices) async {
    // PDF 문서 생성
    final pdf = pw.Document();

    // 한글 폰트 로드 (Noto Sans KR)
    final font = await PdfGoogleFonts.notoSansKRRegular();
    final fontBold = await PdfGoogleFonts.notoSansKRBold();

    // 더미 분석 데이터 (추후 실제 AI 분석 결과로 교체)
    final analysisResults = _generateDummyAnalysis(devices);

    // 페이지 1: 표지 + 요약
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => _buildCoverPage(context, devices, fontBold),
      ),
    );

    // 페이지 2: 장치별 상세 보고
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildPageHeader(context),
        footer: (context) => _buildPageFooter(context),
        build: (context) => _buildDeviceDetailPages(context, devices, analysisResults),
      ),
    );

    // 페이지 3: 구조물 안전 점검 요약
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildPageHeader(context),
        footer: (context) => _buildPageFooter(context),
        build: (context) => _buildStructureSummaryPage(context),
      ),
    );

    // PDF 미리보기 및 저장 화면 표시
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('AI 안전 진단 보고서', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) => pdf.save(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'AI_안전진단_보고서_$_dateOnly.pdf',
          ),
        ),
      ),
    );
  }

  // ============== 표지 페이지 ==============
  static pw.Widget _buildCoverPage(pw.Context context, List<Device> devices, pw.Font fontBold) {
    final online = devices.where((d) => d.isOnline).length;
    final offline = devices.length - online;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 60),
        // 타이틀
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#0F172A'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('VISION AI', style: pw.TextStyle(font: fontBold, color: PdfColor.fromHex('#00E5FF'), fontSize: 14, letterSpacing: 2)),
              pw.SizedBox(height: 8),
              pw.Text('AI 기반 건축물 구조 안전 진단 보고서', style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 24)),
              pw.SizedBox(height: 4),
              pw.Text('Structural Safety Diagnosis Report', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 12)),
            ],
          ),
        ),
        pw.SizedBox(height: 40),
        // 보고서 정보
        _buildInfoRow('보고서 생성일시', _now),
        _buildInfoRow('보고서 ID', 'RPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
        _buildInfoRow('분석 대상', '등록된 전체 장치 (${devices.length}대)'),
        _buildInfoRow('작성 시스템', 'VISION AI Structural Diagnosis v1.0'),
        pw.SizedBox(height: 40),
        // 요약 통계
        pw.Text('분석 요약', style: pw.TextStyle(font: fontBold, fontSize: 18)),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('전체 장치', '${devices.length}', PdfColor.fromHex('#00E5FF')),
              _buildStatBox('온라인', '$online', PdfColor.fromHex('#22C55E')),
              _buildStatBox('오프라인', '$offline', PdfColor.fromHex('#EF4444')),
              _buildStatBox('분석 정확도', '98.5%', PdfColor.fromHex('#00E5FF')),
            ],
          ),
        ),
        pw.SizedBox(height: 40),
        // 장치 목록 테이블
        pw.Text('등록 장치 목록', style: pw.TextStyle(font: fontBold, fontSize: 18)),
        pw.SizedBox(height: 12),
        _buildDeviceTable(devices),
        pw.Spacer(),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          '본 보고서는 VISION AI 시스템에 의해 자동 생성되었습니다. 보고서 내용은 AI 분석 결과에 기반하며, 최종 판단은 전문가의 검토가 필요합니다.',
          style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
        ),
      ],
    );
  }

  // ============== 장치별 상세 페이지 ==============
  static List<pw.Widget> _buildDeviceDetailPages(pw.Context context, List<Device> devices, List<Map<String, dynamic>> analysisResults) {
    final widgets = <pw.Widget>[];

    widgets.add(pw.Text('장치별 상세 분석 결과', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)));
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(pw.Text('DEVICE ANALYSIS DETAILS', style: pw.TextStyle(color: PdfColor.fromHex('#00E5FF'), fontSize: 10)));
    widgets.add(pw.SizedBox(height: 16));

    for (int i = 0; i < devices.length; i++) {
      final device = devices[i];
      final analysis = analysisResults[i];

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 장치 헤더
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(device.deviceName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: device.isOnline ? PdfColor.fromHex('#DCFCE7') : PdfColor.fromHex('#FEE2E2'),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      device.isOnline ? '온라인' : '오프라인',
                      style: pw.TextStyle(
                        color: device.isOnline ? PdfColor.fromHex('#166534') : PdfColor.fromHex('#991B1B'),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('위치: ${device.location}  |  MAC: ${device.macAddress}', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
              pw.SizedBox(height: 12),
              // 분석 결과
              pw.Text('AI 분석 결과', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              _buildAnalysisTable(analysis),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  // ============== 구조물 안전 점검 요약 ==============
  static List<pw.Widget> _buildStructureSummaryPage(pw.Context context) {
    final structures = [
      {'name': '정보공학관', 'score': 92, 'status': '양호', 'issues': 1},
      {'name': '중앙도서관', 'score': 74, 'status': '주의', 'issues': 3},
      {'name': '학생회관', 'score': 58, 'status': '위험', 'issues': 7},
      {'name': '공학관 A동', 'score': 96, 'status': '양호', 'issues': 0},
      {'name': '제1기숙사', 'score': 81, 'status': '주의', 'issues': 2},
    ];

    return [
      pw.Text('구조물 안전 점검 요약', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
      pw.SizedBox(height: 4),
      pw.Text('STRUCTURE SAFETY SUMMARY', style: pw.TextStyle(color: PdfColor.fromHex('#00E5FF'), fontSize: 10)),
      pw.SizedBox(height: 16),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F172A')),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
        },
        headers: ['구조물명', '안전 점수', '등급', '발견 이슈'],
        data: structures.map((s) => [
          s['name'].toString(),
          '${s['score']}/100',
          s['status'].toString(),
          '${s['issues']}건',
        ]).toList(),
      ),
      pw.SizedBox(height: 24),
      pw.Text('점검 항목 세부 내역', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headers: ['점검 항목', '정보공학관', '중앙도서관', '학생회관', '공학관 A동', '제1기숙사'],
        data: [
          ['외벽 균열 검사', '양호', '주의', '이상', '양호', '양호'],
          ['기둥 구조 점검', '양호', '양호', '주의', '양호', '양호'],
          ['철근 부식도 측정', '양호', '주의', '이상', '양호', '주의'],
          ['방수층 상태 확인', '양호', '양호', '주의', '양호', '양호'],
          ['지반 침하 여부', '양호', '양호', '양호', '양호', '양호'],
          ['소방 설비 점검', '양호', '양호', '이상', '양호', '양호'],
        ],
      ),
      pw.SizedBox(height: 24),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#FEF3C7'),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColor.fromHex('#F59E0B')),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('! ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D97706'), fontSize: 14)),
            pw.Expanded(
              child: pw.Text(
                '학생회관(안전 점수 58점)은 위험 등급으로 판정되었습니다. 즉각적인 정밀 안전 진단 및 보수 작업이 필요합니다. '
                '외벽 균열, 철근 부식, 소방 설비 등 7건의 이슈가 발견되었습니다.',
                style: pw.TextStyle(color: PdfColor.fromHex('#92400E'), fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ============== 헬퍼 위젯들 ==============
  static pw.Widget _buildPageHeader(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('VISION AI - 구조 안전 진단 보고서', style: pw.TextStyle(color: PdfColor.fromHex('#00E5FF'), fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(_dateOnly, style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CONFIDENTIAL - 내부 문서', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8)),
          pw.Text('${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildDeviceTable(List<Device> devices) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F172A')),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      headers: ['No.', '장치명', '위치', 'MAC 주소', '상태'],
      data: devices.asMap().entries.map((e) => [
        '${e.key + 1}',
        e.value.deviceName,
        e.value.location,
        e.value.macAddress,
        e.value.isOnline ? '온라인' : '오프라인',
      ]).toList(),
    );
  }

  static pw.Widget _buildAnalysisTable(Map<String, dynamic> analysis) {
    final items = analysis['items'] as List<Map<String, String>>;
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: ['분석 항목', '결과', '신뢰도', '비고'],
      data: items.map((item) => [
        item['category'] ?? '',
        item['result'] ?? '',
        item['confidence'] ?? '',
        item['note'] ?? '',
      ]).toList(),
    );
  }

  // 더미 분석 데이터 생성
  static List<Map<String, dynamic>> _generateDummyAnalysis(List<Device> devices) {
    return devices.map((device) {
      return {
        'deviceId': device.id,
        'items': [
          {'category': '균열 탐지', 'result': '정상', 'confidence': '97.2%', 'note': '주요 균열 미발견'},
          {'category': '부식 분석', 'result': device.id % 3 == 0 ? '주의' : '정상', 'confidence': '94.8%', 'note': device.id % 3 == 0 ? '경미한 표면 부식 감지' : '이상 없음'},
          {'category': '기울기 측정', 'result': '정상', 'confidence': '99.1%', 'note': '허용 범위 이내'},
          {'category': '진동 분석', 'result': device.id % 5 == 0 ? '경고' : '정상', 'confidence': '96.5%', 'note': device.id % 5 == 0 ? '미세 진동 감지됨' : '정상 범위'},
          {'category': '화재 위험도', 'result': '정상', 'confidence': '98.7%', 'note': '화재 징후 미감지'},
          {'category': '누수 탐지', 'result': '정상', 'confidence': '95.3%', 'note': '누수 없음'},
        ],
      };
    }).toList();
  }
}
