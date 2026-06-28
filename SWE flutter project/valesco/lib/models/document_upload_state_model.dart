class DocumentUploadState {
  final String? documentId;
  final String? fileName;
  final double uploadProgress; // 0.0 to 1.0
  final String status; // idle, uploading, success, error
  final String? errorMessage;
  final DateTime? startTime;

  DocumentUploadState({
    this.documentId,
    this.fileName,
    this.uploadProgress = 0.0,
    this.status = 'idle',
    this.errorMessage,
    this.startTime,
  });

  DocumentUploadState copyWith({
    String? documentId,
    String? fileName,
    double? uploadProgress,
    String? status,
    String? errorMessage,
    DateTime? startTime,
  }) {
    return DocumentUploadState(
      documentId: documentId ?? this.documentId,
      fileName: fileName ?? this.fileName,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
    );
  }
}
