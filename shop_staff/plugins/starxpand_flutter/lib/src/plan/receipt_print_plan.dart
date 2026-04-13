import 'package:equatable/equatable.dart';

import '../models/receipt_document_payload.dart';

enum ReceiptPrintPlanNodeType { image, text, row, divider, spacer, cut, qrCode }

enum ReceiptPrintPlanAlign { left, center, right }

extension ReceiptPrintPlanNodeTypeX on ReceiptPrintPlanNodeType {
  String get wireValue {
    switch (this) {
      case ReceiptPrintPlanNodeType.image:
        return 'image';
      case ReceiptPrintPlanNodeType.text:
        return 'text';
      case ReceiptPrintPlanNodeType.row:
        return 'row';
      case ReceiptPrintPlanNodeType.divider:
        return 'divider';
      case ReceiptPrintPlanNodeType.spacer:
        return 'spacer';
      case ReceiptPrintPlanNodeType.cut:
        return 'cut';
      case ReceiptPrintPlanNodeType.qrCode:
        return 'qr_code';
    }
  }
}

extension ReceiptPrintPlanAlignX on ReceiptPrintPlanAlign {
  String get wireValue {
    switch (this) {
      case ReceiptPrintPlanAlign.left:
        return 'left';
      case ReceiptPrintPlanAlign.center:
        return 'center';
      case ReceiptPrintPlanAlign.right:
        return 'right';
    }
  }
}

class ReceiptPrintPlanDocument extends Equatable {
  const ReceiptPrintPlanDocument({
    this.schema = schemaV1,
    required this.kind,
    this.paperWidthMm = 72,
    this.nodes = const <ReceiptPrintPlanNode>[],
    this.extras = const <String, dynamic>{},
  });

  static const String schemaV1 = 'shop_staff.receipt_plan.v1';

  final String schema;
  final ReceiptDocumentKind kind;
  final int paperWidthMm;
  final List<ReceiptPrintPlanNode> nodes;
  final Map<String, dynamic> extras;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema': schema,
      'kind': kind.wireValue,
      'paperWidthMm': paperWidthMm,
      'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
      'extras': Map<String, dynamic>.from(extras),
    };
  }

  @override
  List<Object?> get props => <Object?>[
    schema,
    kind,
    paperWidthMm,
    nodes,
    extras,
  ];
}

class ReceiptPrintPlanNode extends Equatable {
  const ReceiptPrintPlanNode({
    required this.type,
    this.text,
    this.columns = const <ReceiptPrintPlanColumn>[],
    this.align = ReceiptPrintPlanAlign.left,
    this.bold = false,
    this.widthScale = 1,
    this.heightScale = 1,
    this.imageAssetKey,
    this.imageBase64,
    this.qrData,
    this.spacerLines,
    this.partialCut = true,
  });

  factory ReceiptPrintPlanNode.text(
    String text, {
    ReceiptPrintPlanAlign align = ReceiptPrintPlanAlign.left,
    bool bold = false,
    int widthScale = 1,
    int heightScale = 1,
  }) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.text,
      text: text,
      align: align,
      bold: bold,
      widthScale: widthScale,
      heightScale: heightScale,
    );
  }

  factory ReceiptPrintPlanNode.row(List<ReceiptPrintPlanColumn> columns) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.row,
      columns: columns,
    );
  }

  factory ReceiptPrintPlanNode.divider() {
    return const ReceiptPrintPlanNode(type: ReceiptPrintPlanNodeType.divider);
  }

  factory ReceiptPrintPlanNode.spacer([int lines = 1]) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.spacer,
      spacerLines: lines <= 0 ? 1 : lines,
    );
  }

  factory ReceiptPrintPlanNode.cut({bool partial = true}) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.cut,
      partialCut: partial,
    );
  }

  factory ReceiptPrintPlanNode.imageAsset(
    String imageAssetKey, {
    ReceiptPrintPlanAlign align = ReceiptPrintPlanAlign.center,
  }) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.image,
      align: align,
      imageAssetKey: imageAssetKey,
    );
  }

  factory ReceiptPrintPlanNode.imageBase64(
    String imageBase64, {
    ReceiptPrintPlanAlign align = ReceiptPrintPlanAlign.center,
  }) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.image,
      align: align,
      imageBase64: imageBase64,
    );
  }

  factory ReceiptPrintPlanNode.qrCode(
    String qrData, {
    ReceiptPrintPlanAlign align = ReceiptPrintPlanAlign.center,
  }) {
    return ReceiptPrintPlanNode(
      type: ReceiptPrintPlanNodeType.qrCode,
      align: align,
      qrData: qrData,
    );
  }

  final ReceiptPrintPlanNodeType type;
  final String? text;
  final List<ReceiptPrintPlanColumn> columns;
  final ReceiptPrintPlanAlign align;
  final bool bold;
  final int widthScale;
  final int heightScale;
  final String? imageAssetKey;
  final String? imageBase64;
  final String? qrData;
  final int? spacerLines;
  final bool partialCut;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.wireValue,
      'align': align.wireValue,
      'bold': bold,
      'widthScale': widthScale,
      'heightScale': heightScale,
      if (text != null) 'text': text,
      if (columns.isNotEmpty)
        'columns': columns
            .map((column) => column.toJson())
            .toList(growable: false),
      if (imageAssetKey != null) 'imageAssetKey': imageAssetKey,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (qrData != null) 'qrData': qrData,
      if (spacerLines != null) 'spacerLines': spacerLines,
      'partialCut': partialCut,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    type,
    text,
    columns,
    align,
    bold,
    widthScale,
    heightScale,
    imageAssetKey,
    imageBase64,
    qrData,
    spacerLines,
    partialCut,
  ];
}

class ReceiptPrintPlanColumn extends Equatable {
  const ReceiptPrintPlanColumn({
    required this.text,
    this.align = ReceiptPrintPlanAlign.left,
    this.flex = 1,
    this.bold = false,
  });

  final String text;
  final ReceiptPrintPlanAlign align;
  final int flex;
  final bool bold;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'text': text,
      'align': align.wireValue,
      'flex': flex,
      'bold': bold,
    };
  }

  @override
  List<Object?> get props => <Object?>[text, align, flex, bold];
}
