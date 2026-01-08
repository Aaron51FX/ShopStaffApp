import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'receipt_factory.dart';
import '../../domain/services/receipt_renderer.dart';

final receiptRendererProvider = Provider<ReceiptRenderer>((_) => const ReceiptRendererImpl());
