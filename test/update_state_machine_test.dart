import 'package:dipi/features/app_update/domain/app_release.dart';
import 'package:dipi/features/app_update/domain/release_asset.dart';
import 'package:dipi/features/app_update/domain/semantic_version.dart';
import 'package:dipi/features/app_update/domain/update_machine.dart';
import 'package:dipi/features/app_update/domain/update_phase.dart';
import 'package:dipi/features/app_update/domain/update_state.dart';
import 'package:flutter_test/flutter_test.dart';

AppRelease _release() => const AppRelease(
  tag: 'v1.2.0',
  version: SemanticVersion(1, 2, 0),
  body: 'notes',
  assets: [
    ReleaseAsset(
      name: 'dipi-v1.2.0-arm64-v8a.apk',
      sizeInBytes: 100,
      downloadUrl: 'https://github.com/a.apk',
    ),
  ],
);

void main() {
  const initial = UpdateState();

  test('no release hides the icon', () {
    final next = UpdateMachine.afterCheck(
      initial,
      release: null,
      onWifi: true,
      wifiOnly: true,
    );
    expect(next.phase, UpdatePhase.hidden);
  });

  test('Wi-Fi starts the download by itself', () {
    final next = UpdateMachine.afterCheck(
      initial,
      release: _release(),
      onWifi: true,
      wifiOnly: true,
    );
    expect(next.phase, UpdatePhase.downloading);
  });

  test('mobile data waits in the available state when Wi-Fi-only', () {
    final next = UpdateMachine.afterCheck(
      initial,
      release: _release(),
      onWifi: false,
      wifiOnly: true,
    );
    expect(next.phase, UpdatePhase.available);
  });

  test('mobile data downloads when Wi-Fi-only is off', () {
    final next = UpdateMachine.afterCheck(
      initial,
      release: _release(),
      onWifi: false,
      wifiOnly: false,
    );
    expect(next.phase, UpdatePhase.downloading);
  });

  test('progress goes to downloading and remembers the size', () {
    final next = UpdateMachine.onProgress(
      const UpdateState(phase: UpdatePhase.downloading),
      40,
      100,
    );
    expect(next.phase, UpdatePhase.downloading);
    expect(next.progress, 0.4);
  });

  test('finishing goes to ready', () {
    final started = UpdateMachine.afterCheck(
      initial,
      release: _release(),
      onWifi: true,
      wifiOnly: true,
    );
    final ready = UpdateMachine.onDownloaded(started);
    expect(ready.phase, UpdatePhase.ready);
  });

  test('an error keeps the release so retry can work', () {
    final started = UpdateMachine.afterCheck(
      initial,
      release: _release(),
      onWifi: true,
      wifiOnly: true,
    );
    final failed = UpdateMachine.onError(started, 'boom');
    expect(failed.phase, UpdatePhase.error);
    expect(failed.errorMessage, 'boom');
    expect(failed.release, isNotNull);

    final again = UpdateMachine.onStartAgain(failed);
    expect(again.phase, UpdatePhase.downloading);
  });

  test('cancel returns to available', () {
    final next = UpdateMachine.onCancelled(
      const UpdateState(phase: UpdatePhase.downloading, totalBytes: 100),
    );
    expect(next.phase, UpdatePhase.available);
    expect(next.receivedBytes, 0);
  });

  group('shouldAutoOpen', () {
    test('opens when ready and not dismissed', () {
      expect(
        UpdateMachine.shouldAutoOpen(
          const UpdateState(phase: UpdatePhase.ready),
          blockedByForm: false,
        ),
        isTrue,
      );
    });

    test('does not open while a form is open', () {
      expect(
        UpdateMachine.shouldAutoOpen(
          const UpdateState(phase: UpdatePhase.ready),
          blockedByForm: true,
        ),
        isFalse,
      );
    });

    test('does not open after the user pressed later', () {
      final dismissed = UpdateMachine.onDismissed(
        const UpdateState(phase: UpdatePhase.ready),
      );
      expect(dismissed.dismissedThisSession, isTrue);
      expect(
        UpdateMachine.shouldAutoOpen(dismissed, blockedByForm: false),
        isFalse,
      );
    });

    test('never opens in other phases', () {
      for (final phase in [
        UpdatePhase.hidden,
        UpdatePhase.available,
        UpdatePhase.downloading,
        UpdatePhase.error,
      ]) {
        expect(
          UpdateMachine.shouldAutoOpen(
            UpdateState(phase: phase),
            blockedByForm: false,
          ),
          isFalse,
        );
      }
    });
  });
}
