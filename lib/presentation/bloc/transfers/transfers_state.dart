import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados del TransfersBloc
abstract class TransfersState extends Equatable {
  const TransfersState();
  @override
  List<Object?> get props => [];
}

class TransfersInitial extends TransfersState {
  const TransfersInitial();
}

class TransfersLoading extends TransfersState {
  const TransfersLoading();
}

class TransfersLoaded extends TransfersState {
  final List<TransferData> transfers;

  const TransfersLoaded(this.transfers);

  @override
  List<Object?> get props => [transfers];
}

class TransfersEmpty extends TransfersState {
  const TransfersEmpty();
}

class TransferDetailsLoaded extends TransfersState {
  final TransferData transfer;
  final List<TransferDetailData> details;
  final String? fromLocationName;
  final String? toLocationName;
  final String? createdByName;
  final String? approvedByName;
  final String? receivedByName;

  const TransferDetailsLoaded({
    required this.transfer,
    required this.details,
    this.fromLocationName,
    this.toLocationName,
    this.createdByName,
    this.approvedByName,
    this.receivedByName,
  });

  @override
  List<Object?> get props => [
    transfer,
    details,
    fromLocationName,
    toLocationName,
    createdByName,
    approvedByName,
    receivedByName,
  ];
}

class TransferCreated extends TransfersState {
  final int transferId;

  const TransferCreated(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class TransferApproved extends TransfersState {
  final int transferId;

  const TransferApproved(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class TransferReceived extends TransfersState {
  final int transferId;

  const TransferReceived(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class TransferCancelled extends TransfersState {
  final int transferId;

  const TransferCancelled(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class TransfersError extends TransfersState {
  final String message;

  const TransfersError(this.message);

  @override
  List<Object?> get props => [message];
}
