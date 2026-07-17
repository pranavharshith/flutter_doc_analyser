import 'package:flutter_test/flutter_test.dart';
import 'package:vortex_dashboard/utils/document_validators.dart';

void main() {
  group('DocumentValidators', () {
    test('reject short or non-digit Aadhaar', () {
      expect(DocumentValidators.validateAadhaar('123'), isFalse);
      expect(DocumentValidators.validateAadhaar('abcd efgh ijkl'), isFalse);
    });

    test('hash is stable and lowercase hex', () {
      final a = DocumentValidators.hashDocumentNumber('ABC1234567');
      final b = DocumentValidators.hashDocumentNumber('abc-123-4567');
      expect(a, equals(b));
      expect(a.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(a), isTrue);
    });

    test('voter ID format accepts common EPIC patterns', () {
      expect(DocumentValidators.isValidVoterIdFormat('ABC1234567'), isTrue);
      expect(DocumentValidators.isValidVoterIdFormat('AB1234567'), isTrue);
      expect(DocumentValidators.isValidVoterIdFormat('!!'), isFalse);
    });
  });
}
