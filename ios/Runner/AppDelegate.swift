import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var countdownPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "local_tasks/countdown_sound",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "playCountdown" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.playCountdownTone()
        result(nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func playCountdownTone() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try audioSession.setActive(true, options: [])

      let player = try AVAudioPlayer(
        data: makeCountdownWav(),
        fileTypeHint: AVFileType.wav.rawValue
      )
      player.volume = 1.0
      player.prepareToPlay()
      player.play()
      countdownPlayer = player
    } catch {
      // Flutter falls back to the platform alert sound if native audio is unavailable.
    }
  }

  private func makeCountdownWav() -> Data {
    let sampleRate: UInt32 = 44_100
    let duration = 0.18
    let frequency = 880.0
    let sampleCount = Int(Double(sampleRate) * duration)
    let dataSize = UInt32(sampleCount * MemoryLayout<Int16>.size)
    var data = Data()

    data.append(contentsOf: Data("RIFF".utf8))
    appendUInt32(36 + dataSize, to: &data)
    data.append(contentsOf: Data("WAVE".utf8))
    data.append(contentsOf: Data("fmt ".utf8))
    appendUInt32(16, to: &data)
    appendUInt16(1, to: &data)
    appendUInt16(1, to: &data)
    appendUInt32(sampleRate, to: &data)
    appendUInt32(sampleRate * 2, to: &data)
    appendUInt16(2, to: &data)
    appendUInt16(16, to: &data)
    data.append(contentsOf: Data("data".utf8))
    appendUInt32(dataSize, to: &data)

    for index in 0..<sampleCount {
      let time = Double(index) / Double(sampleRate)
      let fadeIn = min(time / 0.012, 1.0)
      let fadeOut = min((duration - time) / 0.035, 1.0)
      let envelope = max(0.0, min(fadeIn, fadeOut))
      let sample = Int16(
        sin(2.0 * Double.pi * frequency * time) *
          0.32 * envelope * Double(Int16.max)
      )
      appendUInt16(UInt16(bitPattern: sample), to: &data)
    }
    return data
  }

  private func appendUInt16(_ value: UInt16, to data: inout Data) {
    var littleEndianValue = value.littleEndian
    withUnsafeBytes(of: &littleEndianValue) {
      data.append(contentsOf: $0)
    }
  }

  private func appendUInt32(_ value: UInt32, to data: inout Data) {
    var littleEndianValue = value.littleEndian
    withUnsafeBytes(of: &littleEndianValue) {
      data.append(contentsOf: $0)
    }
  }
}
