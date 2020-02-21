/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import RxSwift
import RxCocoa

class SimplePlayer: NSObject {
  private var players: [String: AVAudioPlayer] = [:]
  private let bundle: Bundle
  private let session = AVAudioSession.sharedInstance()

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  func prepare(_ audioFiles: [AudioFileRepresentable],
               category: AVAudioSession.Category = .soloAmbient) throws {
    for audioFile in audioFiles where players[audioFile.audioFile] == nil {
      guard let ext = audioFile.audioFile.components(separatedBy: ".").last?.lowercased() else {
        throw Error.invalidAudioFile
      }

      let fileName = audioFile.audioFile.replacingOccurrences(of: ".\(ext)", with: "")

      guard let fileURL = bundle.url(forResource: fileName, withExtension: ext) else {
        throw Error.invalidAudioFile
      }

      players[audioFile.audioFile] = try AVAudioPlayer(contentsOf: fileURL)
    }

    try session.setCategory(category, mode: .default, options: [])
    try session.setActive(true, options: [])
  }

  func play(_ audioFile: AudioFileRepresentable) throws {
    try prepare([audioFile])

    guard let player = players[audioFile.audioFile] else {
      fatalError("This should never happen")
    }

    player.play()
  }

  deinit {
    try! session.setActive(false, options: [])
    players = [:]
  }
}

// MARK: - Errors
extension SimplePlayer {
  enum Error: Swift.Error {
    case invalidAudioFile
  }
}

// MARK: - AudioFileRepresentable protocol
protocol AudioFileRepresentable {
  var audioFile: String { get }
}

// MARK: - Reactive Extension
extension Reactive where Base: SimplePlayer {
  var audioFile: Binder<AudioFileRepresentable> {
    return Binder(base) { player, file in
      do {
        try player.play(file)
      } catch let err {
        fatalError("Player has been bound with an invalid audio file: \(err)")
      }
    }
  }
}
