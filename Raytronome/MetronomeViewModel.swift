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

import RxSwift
import RxCocoa

class MetronomeViewModel {
  // Inputs
  public let steppedNumerator: BehaviorSubject<Double>
  public let steppedDenominator: BehaviorSubject<Double>
  public let tempo: BehaviorSubject<Float>
  public let tappedPlayPause: PublishSubject<Void> = .init()

  // Outputs
  public let numeratorText: Driver<String>
  public let denominatorText: Driver<String>
  public let numeratorValue: Driver<Double>
  public let maxNumerator: Driver<Double>
  public let signatureText: Driver<String>
  public let tempoText: Driver<String>
  public let beat: Driver<Beat>
  public let beatType: Driver<BeatType>
  public let isPlaying: Driver<Bool>

  init(initialMeter: Meter = Meter(signature: "4/4"),
       initialTempo: Float = 120,
       autoplay: Bool = false,
       beatScheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
    isPlaying = tappedPlayPause
      .scan(autoplay) { v, _ in !v }
      .startWith(autoplay)
      .asDriver(onErrorJustReturn: false)

    tempo = BehaviorSubject(value: initialTempo)
    steppedNumerator = BehaviorSubject(value: Double(initialMeter.numerator))

    // Revert initial meter denominator to stepper value.
    // log2(4, 8, 6, 32) = 1, 2, 3, 4
    steppedDenominator = BehaviorSubject(value: log2(Double(initialMeter.denominator)) - 1)

    // Denominator stepper values are 1 through 4.
    //
    // 2 ^ (n + 1) = actual denominator
    // f(1, 2, 3, 4) = 4, 8, 16, 32
    let currentDenominator = steppedDenominator
      .map { pow(2, $0 + 1) }
      .share(replay: 1)

    maxNumerator = currentDenominator
      .asDriver(onErrorJustReturn: 0)

    numeratorValue = steppedNumerator
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: 0)

    let meter = Observable
      .combineLatest(numeratorValue.asObservable(),
                     currentDenominator) { (Int($0), Int($1)) }
      .map(Meter.init)
      .distinctUntilChanged()
      .share(replay: 1)

    numeratorText = meter
      .map { "\($0.numerator)" }
      .asDriver(onErrorJustReturn: "")

    denominatorText = meter
      .map( { "\($0.denominator)" })
      .asDriver(onErrorJustReturn: "")

    signatureText = meter
      .map { "\($0.signature)" }
      .asDriver(onErrorJustReturn: "")

    let currentTempo = tempo
      .map { Int(round($0)) }
      .share(replay: 1)

    tempoText = currentTempo
      .map { "\($0) BPM" }
      .asDriver(onErrorJustReturn: "")

    //-----------------------------------------
    //              BEAT LOGIC                |
    //-----------------------------------------

    // How often should a beat be triggered
    let beatInterval = Observable
      .combineLatest(currentTempo, meter)
      .map { (tempo, meter) -> Double in
        // Beats per second multiplied by subdivision
        let subdivision = Double(meter.denominator / 4)
        let perSecond = Double(tempo / 60) * subdivision
        return 1.0 / perSecond
      }

    // Create a new "beat" stream whenever the interval changes
    typealias BeatAndCycle = (beat: Beat, totalBeats: Int)
    let beats = Observable.combineLatest(beatInterval,
                                         isPlaying.asObservable()) { (interval: $0, isPlaying: $1) }
      .flatMapLatest { beat -> Observable<BeatAndCycle> in
        guard beat.isPlaying else { return .never() }

        return Observable<Int>
          .interval(beat.interval, scheduler: beatScheduler)
          .withLatestFrom(meter)
          .scan((currentBeat: -1, totalBeats: -1)) { beats, meter in
            let currentBeat = (beats.currentBeat + 1) % meter.numerator
            let totalBeats = beats.totalBeats + 1

            return (currentBeat, totalBeats)
          }
          .map { ($0.currentBeat == 0 ? .first : .regular, $0.totalBeats) }
      }
      .asDriver(onErrorJustReturn: (.first, 1))

    beat = beats.map { $0.beat }

    beatType = beats.map { $0.totalBeats % 2 == 0 ? .even : .odd }
  }
}
