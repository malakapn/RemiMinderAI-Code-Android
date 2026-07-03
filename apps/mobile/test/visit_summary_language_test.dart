import 'package:flutter_test/flutter_test.dart';
import 'package:RemiMinder/features/patient/data/services/visit_summary_gemini_prompt.dart';

void main() {
  test('geminiLanguageInstructionForCode returns Spanish directive', () {
    expect(
      geminiLanguageInstructionForCode('es'),
      'Generate the entire response in Spanish language.',
    );
  });

  test('geminiLanguageInstructionForCode returns Hindi directive', () {
    expect(
      geminiLanguageInstructionForCode('hi'),
      'Generate the entire response in Hindi language.',
    );
  });

  test('geminiLanguageInstructionForCode returns French directive', () {
    expect(
      geminiLanguageInstructionForCode('fr'),
      'Generate the entire response in French language.',
    );
  });

  test('geminiLanguageInstructionForCode returns Portuguese directive', () {
    expect(
      geminiLanguageInstructionForCode('pt'),
      'Generate the entire response in Portuguese language.',
    );
  });

  test('geminiLanguageInstructionForCode returns Bengali directive', () {
    expect(
      geminiLanguageInstructionForCode('bn'),
      'Generate the entire response in Bengali language.',
    );
  });

  test('geminiLanguageInstructionForCode returns Tamil directive', () {
    expect(
      geminiLanguageInstructionForCode('ta'),
      'Generate the entire response in Tamil language.',
    );
  });

  test('geminiLanguageInstructionForCode defaults to English', () {
    expect(
      geminiLanguageInstructionForCode('unknown'),
      'Generate the entire response in English language.',
    );
  });
}
