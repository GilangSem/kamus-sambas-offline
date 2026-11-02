import 'package:flutter_test/flutter_test.dart';

import 'package:kamus_app/utils/version.dart';

void main() {
  test('membandingkan versi semantik sederhana', () {
    expect(compareVersions('1.2.3', '1.2.3'), 0);
    expect(compareVersions('1.2.4', '1.2.3'), greaterThan(0));
    expect(compareVersions('1.2.2', '1.2.3'), lessThan(0));
    expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(compareVersions('2.0', '1.99.99'), greaterThan(0));
  });

  test('mengabaikan build dan prerelease', () {
    expect(compareVersions('0.1.0+3', '0.1.0'), 0);
    expect(compareVersions('0.1.0-beta.2', '0.1.0'), 0);
    expect(compareVersions('v0.1.0', '0.1.0'), 0);
  });

  test('isVersionAtLeast menghormati versi minimum', () {
    expect(isVersionAtLeast('0.1.0', '0.1.0'), isTrue);
    expect(isVersionAtLeast('0.2.0', '0.1.0'), isTrue);
    expect(isVersionAtLeast('0.0.9', '0.1.0'), isFalse);
    expect(isVersionAtLeast('1.0', '1.0.1'), isFalse);
  });
}
