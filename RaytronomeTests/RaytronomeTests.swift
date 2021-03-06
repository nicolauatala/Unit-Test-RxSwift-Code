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

import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import Raytronome

class RaytronomeTests: XCTestCase {
  var viewModel: MetronomeViewModel!
	
	var scheduler: TestScheduler!
	var disposeBag: DisposeBag!

  override func setUp() {
    viewModel = MetronomeViewModel()
		
		// The TestScheduler‘s initializer takes in an initialClock argument that defines the “starting time” for your stream. A new DisposeBag will take care of getting rid of any subscriptions left by your previous test.
//		scheduler = TestScheduler(initialClock: 0)
		scheduler = TestScheduler(initialClock: 0, resolution: 0.01)
		disposeBag = DisposeBag()
  }
	
	func testNumeratorStartsAt4() throws {
		XCTAssertEqual(try viewModel.numeratorText.toBlocking().first(), "4")
		XCTAssertEqual(try viewModel.numeratorValue.toBlocking().first(), 4)
	}
	
	func testDenominatorStartsAt4() throws {
		XCTAssertEqual(try viewModel.denominatorText.toBlocking().first(), "4")
	}
	
	func testTempoTextStartAt120BPM() throws {
		XCTAssertEqual(try viewModel.tempoText.toBlocking().first(), "120 BPM")
	}
	
	func testSignatureTextStartAt44() throws {
		XCTAssertEqual(try viewModel.signatureText.toBlocking().first(), "4/4")
	}
	
	func testTappedPlayPauseChangesIsPlaying() {
		// 1
		let isPlaying = scheduler.createObserver(Bool.self)
		
		// 2
		viewModel.isPlaying
			.drive(isPlaying)
			.disposed(by: disposeBag)
		
		// 3
		scheduler.createColdObservable([.next(10, ()),
																		.next(20, ()),
																		.next(30, ())])
			.bind(to: viewModel.tappedPlayPause)
			.disposed(by: disposeBag)
		
		// 4
		scheduler.start()
		
		// 5
		XCTAssertEqual(isPlaying.events, [
			.next(0, false),
			.next(10, true),
			.next(20, false),
			.next(30, true)
		])
	}
	
	func testModifyingNumeratorUpdatesNumeratorText() {
		let numerator = scheduler.createObserver(String.self)
		
		viewModel.numeratorText
			.drive(numerator)
			.disposed(by: disposeBag)
		
		scheduler.createColdObservable([.next(10, 3),
																		.next(15, 1)])
			.bind(to: viewModel.steppedNumerator)
			.disposed(by: disposeBag)
		
		scheduler.start()
		
		XCTAssertEqual(numerator.events, [
			.next(0, "4"),
			.next(10, "3"),
			.next(15, "1")
		])
	}
	
	func testModifyingDenominatorUpdatesNumeratorText() {
		let denominator = scheduler.createObserver(String.self)
		
		viewModel.denominatorText
			.drive(denominator)
			.disposed(by: disposeBag)
		
		// Denominator is 2 to the power of `steppedDenominator + 1`.
		// f(1, 2, 3, 4) = 4, 8, 16, 32
		scheduler.createColdObservable([.next(10, 2),
																		.next(15, 4),
																		.next(20, 3),
																		.next(25, 1)])
			.bind(to: viewModel.steppedDenominator)
			.disposed(by: disposeBag)
		
		scheduler.start()
		
		XCTAssertEqual(denominator.events, [
			.next(0, "4"),
			.next(10, "8"),
			.next(15, "32"),
			.next(20, "16"),
			.next(25, "4")
		])
	}
	
	func testModifyingTempoUpdatesTempoText() {
		let tempo = scheduler.createObserver(String.self)
		
		viewModel.tempoText
			.drive(tempo)
			.disposed(by: disposeBag)
		
		scheduler.createColdObservable([.next(10, 75),
																		.next(15, 90),
																		.next(20, 180),
																		.next(25, 60)])
			.bind(to: viewModel.tempo)
			.disposed(by: disposeBag)
		
		scheduler.start()
		
		XCTAssertEqual(tempo.events, [
			.next(0, "120 BPM"),
			.next(10, "75 BPM"),
			.next(15, "90 BPM"),
			.next(20, "180 BPM"),
			.next(25, "60 BPM")
		])
	}
	
	func testModifyingSignatureUpdatesSignatureText() {
		// 1
		let signature = scheduler.createObserver(String.self)
		
		viewModel.signatureText
			.drive(signature)
			.disposed(by: disposeBag)
		
		// 2
		scheduler.createColdObservable([.next(5, 3),
																		.next(10, 1),
																		
																		.next(20, 5),
																		.next(25, 7),
																		
																		.next(35, 12),
																		
																		.next(45, 24),
																		.next(50, 32)
		])
			.bind(to: viewModel.steppedNumerator)
			.disposed(by: disposeBag)
		
		// Denominator is 2 to the power of `steppedDenominator + 1`.
		// f(1, 2, 3, 4) = 4, 8, 16, 32
		scheduler.createColdObservable([.next(15, 2), // switch to 8ths
			.next(30, 3), // switch to 16ths
			.next(40, 4)  // switch to 32nds
		])
			.bind(to: viewModel.steppedDenominator)
			.disposed(by: disposeBag)
		
		// 3
		scheduler.start()
		
		// 4
		XCTAssertEqual(signature.events, [
			.next(0, "4/4"),
			.next(5, "3/4"),
			.next(10, "1/4"),
			
			.next(15, "1/8"),
			.next(20, "5/8"),
			.next(25, "7/8"),
			
			.next(30, "7/16"),
			.next(35, "12/16"),
			
			.next(40, "12/32"),
			.next(45, "24/32"),
			.next(50, "32/32")
		])
	}
	
	func testModifyingDenominatorUpdatesNumeratorValueIfExceedsMaximum() {
		// 1
		let numerator = scheduler.createObserver(Double.self)
		
		viewModel.numeratorValue
			.drive(numerator)
			.disposed(by: disposeBag)
		
		// 2
		
		// Denominator is 2 to the power of `steppedDenominator + 1`.
		// f(1, 2, 3, 4) = 4, 8, 16, 32
		scheduler.createColdObservable([
			.next(5, 4), // switch to 32nds
			.next(15, 3), // switch to 16ths
			.next(20, 2), // switch to 8ths
			.next(25, 1)  // switch to 4ths
		])
			.bind(to: viewModel.steppedDenominator)
			.disposed(by: disposeBag)
		
		scheduler.createColdObservable([.next(10, 24)])
			.bind(to: viewModel.steppedNumerator)
			.disposed(by: disposeBag)
		
		// 3
		scheduler.start()
		
		// 4
		XCTAssertEqual(numerator.events, [
			.next(0, 4), // Expected to be 4/4
			.next(10, 24), // Expected to be 24/32
			.next(15, 16), // Expected to be 16/16
			.next(20, 8), // Expected to be 8/8
			.next(25, 4) // Expected to be 4/4
		])
	}
	
	func testBeatBy32() {
		// 1
		viewModel = MetronomeViewModel(initialMeter: Meter(signature: "4/32"),
																	 autoplay: true,
																	 beatScheduler: scheduler)
		
		// 2
		let beat = scheduler.createObserver(Beat.self)
		viewModel.beat.asObservable()
			.take(8)
			.bind(to: beat)
			.disposed(by: disposeBag)
		
		// 3
		scheduler.start()
		
		XCTAssertEqual(beat.events, [
			.next(6, .first),
			.next(12, .regular),
			.next(18, .regular),
			.next(24, .regular),
			.next(30, .first),
			.next(36, .regular),
			.next(42, .regular),
			.next(48, .regular),
			.completed(48)
		])
	}
	
	func testBeatBy4() {
		scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
		
		viewModel = MetronomeViewModel(initialMeter: Meter(signature: "4/4"),
																	 autoplay: true,
																	 beatScheduler: scheduler)
		
		let beat = scheduler.createObserver(Beat.self)
		viewModel.beat.asObservable()
			.take(8)
			.bind(to: beat)
			.disposed(by: disposeBag)
		
		scheduler.start()
		
		XCTAssertEqual(beat.events, [
			.next(5, .first),
			.next(10, .regular),
			.next(15, .regular),
			.next(20, .regular),
			.next(25, .first),
			.next(30, .regular),
			.next(35, .regular),
			.next(40, .regular),
			.completed(40)
		])
	}
	
}
