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

import UIKit
import RxSwift
import RxCocoa

final public class MetronomeViewController: UIViewController {
  // MARK: - Outlets
  @IBOutlet private var imgMetronome: UIImageView!

  @IBOutlet private var stepNumerator: UIStepper!
  @IBOutlet private var stepDenominator: UIStepper!

  @IBOutlet private var lblNumerator: UILabel!
  @IBOutlet private var lblDenominator: UILabel!
  @IBOutlet private var lblSignature: UILabel!

  @IBOutlet private var sliderTempo: UISlider!
  @IBOutlet private var lblTempo: UILabel!

  @IBOutlet private var btnPlayBause: UIButton!

  private let disposeBag = DisposeBag()

  // MARK: - Dependencies
  // In a real-life example, these would all be injected
  // externally, and not created by the ViewController itself.
  private let viewModel = MetronomeViewModel()
  private let player = SimplePlayer()

  // MARK: - Lifecycle
  public override func viewDidLoad() {
    super.viewDidLoad()

    try! player.prepare(Beat.allCases)

    // Prevent bindings and layout while testing.
    // Usually, this doesn't matter, but since we're playing audio,
    // this could get a tad annoying ;-]
    guard !UIApplication.isBeingTested else {
      return
    }

    //---------------|
    //   Bindings    |
    //---------------|

    // Inputs
    stepNumerator.rx.value
      .bind(to: viewModel.steppedNumerator)
      .disposed(by: disposeBag)

    stepDenominator.rx.value
      .bind(to: viewModel.steppedDenominator)
      .disposed(by: disposeBag)

    sliderTempo.rx.value
      .bind(to: viewModel.tempo)
      .disposed(by: disposeBag)

    btnPlayBause.rx.tap
      .bind(to: viewModel.tappedPlayPause)
      .disposed(by: disposeBag)

    // Outputs
    viewModel.numeratorText
      .drive(lblNumerator.rx.text)
      .disposed(by: disposeBag)

    viewModel.numeratorValue
      .drive(stepNumerator.rx.value)
      .disposed(by: disposeBag)

    viewModel.denominatorText
      .drive(lblDenominator.rx.text)
      .disposed(by: disposeBag)

    viewModel.maxNumerator
      .drive(stepNumerator.rx.maximumValue)
      .disposed(by: disposeBag)

    viewModel.signatureText
      .drive(lblSignature.rx.text)
      .disposed(by: disposeBag)

    viewModel.tempoText
      .drive(lblTempo.rx.text)
      .disposed(by: disposeBag)

    Driver.merge(
      viewModel.beatType.map { $0.image },
      viewModel.isPlaying.filter { !$0 }.map { _ in UIImage(named: "MetronomeCenter") }
    )
    .drive(imgMetronome.rx.image)
    .disposed(by: disposeBag)

    viewModel.isPlaying
      .map { UIImage(named: $0 ? "BtnStop" : "BtnPlay") }
      .drive(btnPlayBause.rx.image(for: .normal))
      .disposed(by: disposeBag)

    viewModel.beat
      .map { $0 as AudioFileRepresentable }
      .drive(player.rx.audioFile)
      .disposed(by: disposeBag)
  }
}
