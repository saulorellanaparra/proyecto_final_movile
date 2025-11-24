import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados del PurchasesBloc
abstract class PurchasesState extends Equatable {
  const PurchasesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PurchasesInitial extends PurchasesState {
  const PurchasesInitial();
}

/// Cargando compras
class PurchasesLoading extends PurchasesState {
  const PurchasesLoading();
}

/// Compras cargadas
class PurchasesLoaded extends PurchasesState {
  final List<PurchaseData> purchases;

  const PurchasesLoaded(this.purchases);

  @override
  List<Object?> get props => [purchases];
}

/// Sin compras
class PurchasesEmpty extends PurchasesState {
  const PurchasesEmpty();
}

/// Detalles de compra cargados
class PurchaseDetailsLoaded extends PurchasesState {
  final PurchaseData purchase;
  final List<PurchaseDetailData> details;

  const PurchaseDetailsLoaded({
    required this.purchase,
    required this.details,
  });

  @override
  List<Object?> get props => [purchase, details];
}

/// Compra creada exitosamente
class PurchaseCreated extends PurchasesState {
  final int purchaseId;
  final double total;

  const PurchaseCreated({
    required this.purchaseId,
    required this.total,
  });

  @override
  List<Object?> get props => [purchaseId, total];
}

/// Compra marcada como recibida
class PurchaseMarkedAsReceived extends PurchasesState {
  final int purchaseId;

  const PurchaseMarkedAsReceived(this.purchaseId);

  @override
  List<Object?> get props => [purchaseId];
}

/// Error en compras
class PurchasesError extends PurchasesState {
  final String message;

  const PurchasesError(this.message);

  @override
  List<Object?> get props => [message];
}
