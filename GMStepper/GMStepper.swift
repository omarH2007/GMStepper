//
//  GMStepper.swift
//  GMStepper
//
//  Created by Gunay Mert Karadogan on 1/7/15.
//  Copyright © 2015 Gunay Mert Karadogan. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class GMStepper: UIControl, UITextFieldDelegate {
    
    public var onReachMaxValue:(()->Void)?
    private var viewStyle:ViewStyle = .normal
    
    @objc public enum ViewStyle : Int{
        case normal = 0
        case new
        case newInteractive
        case normalInteractive
    }
    
    /// Current value of the stepper. Defaults to 0.
    @objc @IBInspectable public var value: Double = 0 {
        didSet {
            
            if maximumValue > 0 {
                value = min(maximumValue, max(minimumValue, value))
            }
            
            label.text = formattedValue?.description.convertedDigitsToLocale(Locale(identifier: "EN"))
            leftButtonUpdateInterActions()
            rightButtonUpdateInterActions()
        }
    }
    
    private var formattedValue: String? {
        let isInteger = Decimal(value).exponent >= 0
        
        // If we have items, we will display them as steps
        if isInteger && stepValue == 1.0 && items.count > 0 {
            return items[Int(value)]
        }
        else {
            return formatter.string(from: NSNumber(value: value))
        }
    }
    
    
    /// Minimum value. Must be less than maximumValue. Defaults to 0.
    @objc @IBInspectable public var minimumValue: Double = 0 {
        didSet {
            value = min(maximumValue, max(minimumValue, value))
        }
    }
    
    /// Maximum value. Must be more than minimumValue. Defaults to 100.
    @objc @IBInspectable public var maximumValue: Double = 0 {
        didSet {
            value = min(maximumValue, max(minimumValue, value))
        }
    }
    
    /// Step/Increment value as in UIStepper. Defaults to 1.
    @objc @IBInspectable public var stepValue: Double = 1 {
        didSet {
            setupNumberFormatter()
        }
    }
    
    /// The same as UIStepper's autorepeat. If true, holding on the buttons or keeping the pan gesture alters the value repeatedly. Defaults to true.
    @objc @IBInspectable public var autorepeat: Bool = true
    
    /// If the value is integer, it is shown without floating point.
    @objc @IBInspectable public var showIntegerIfDoubleIsInteger: Bool = true {
        didSet {
            setupNumberFormatter()
        }
    }
    
    /// Text on the left button. Be sure that it fits in the button. Defaults to "−".
    @objc @IBInspectable public var leftButtonText: String = "−" {
        didSet {
            leftButton.setTitle(leftButtonText, for: .normal)
        }
    }
    
    /// Text on the right button. Be sure that it fits in the button. Defaults to "+".
    @objc @IBInspectable public var rightButtonText: String = "+" {
        didSet {
            rightButton.setTitle(rightButtonText, for: .normal)
        }
    }
    
    /// Text color of the buttons. Defaults to white.
    @objc @IBInspectable public var buttonsTextColor: UIColor = UIColor.white {
        didSet {
            for button in [leftButton, rightButton] {
                button.setTitleColor(buttonsTextColor, for: .normal)
            }
        }
    }
    
    /// Background color of the buttons. Defaults to dark blue.
    @objc @IBInspectable public var buttonsBackgroundColor: UIColor = UIColor(red:0.21, green:0.5, blue:0.74, alpha:1) {
        didSet {
            for button in [leftButton, rightButton] {
                button.backgroundColor = buttonsBackgroundColor
            }
            if viewStyle == .normal || viewStyle == .normalInteractive   {
                backgroundColor = buttonsBackgroundColor
            }
        }
    }
    
    /// Font of the buttons. Defaults to AvenirNext-Bold, 20.0 points in size.
    @objc public var buttonsFont = UIFont(name: "AvenirNext-Bold", size: 20.0)! {
        didSet {
            for button in [leftButton, rightButton] {
                button.titleLabel?.font = buttonsFont
            }
        }
    }
    
    /// Text color of the middle label. Defaults to white.
    @objc @IBInspectable public var labelTextColor: UIColor = UIColor.white {
        didSet {
            label.textColor = labelTextColor
        }
    }
    
    /// Text color of the middle label. Defaults to white.
    @objc @IBInspectable public var disableColor: UIColor = UIColor.black
    
    /// Text color of the middle label. Defaults to lighter blue.
    @objc @IBInspectable public var labelBackgroundColor: UIColor = UIColor(red:0.26, green:0.6, blue:0.87, alpha:1) {
        didSet {
            label.backgroundColor = labelBackgroundColor
        }
    }
    
    /// Font of the middle label. Defaults to AvenirNext-Bold, 25.0 points in size.
    @objc public var labelFont = UIFont(name: "AvenirNext-Bold", size: 25.0)! {
        didSet {
            label.font = labelFont
        }
    }
    /// Corner radius of the middle label. Defaults to 0.
    @objc @IBInspectable public var labelCornerRadius: CGFloat = 0 {
        didSet {
            label.layer.cornerRadius = labelCornerRadius
            
        }
    }
    
    /// Corner radius of the stepper's layer. Defaults to 4.0.
    @objc @IBInspectable public var cornerRadius: CGFloat = 4.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            clipsToBounds = true
        }
    }
    
    /// Corner radius of the stepper's layer. Defaults to 4.0.
    @objc @IBInspectable public var buttonsCornerRadius: CGFloat = 0.0 {
        didSet {
            rightButton.layer.cornerRadius = buttonsCornerRadius
            leftButton.layer.cornerRadius = buttonsCornerRadius
        }
    }
    
    /// Border width of the stepper and middle label's layer. Defaults to 0.0.
    @objc @IBInspectable public var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
            label.layer.borderWidth = borderWidth
        }
    }
    
    /// Color of the border of the stepper and middle label's layer. Defaults to clear color.
    @objc @IBInspectable public var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
            label.layer.borderColor = borderColor.cgColor
        }
    }
    
    /// Percentage of the middle label's width. Must be between 0 and 1. Defaults to 0.5. Be sure that it is wide enough to show the value.
    @objc @IBInspectable public var labelWidthWeight: CGFloat = 0.5 {
        didSet {
            labelWidthWeight = min(1, max(0, labelWidthWeight))
            setNeedsLayout()
        }
    }
    
    /// Color of the flashing animation on the buttons in case the value hit the limit.
    @objc @IBInspectable public var limitHitAnimationColor: UIColor = UIColor(red:0.26, green:0.6, blue:0.87, alpha:1)
    
    /// Formatter for displaying the current value
    let formatter = NumberFormatter()
    
    /**
     Width of the sliding animation. When buttons clicked, the middle label does a slide animation towards to the clicked button. Defaults to 5.
     */
    let labelSlideLength: CGFloat = 5
    
    /// Duration of the sliding animation
    let labelSlideDuration = TimeInterval(0.1)
    
    /// Duration of the animation when the value hits the limit.
    let limitHitAnimationDuration = TimeInterval(0.1)
    
    lazy var leftButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.leftButtonText, for: .normal)
        button.setTitleColor(self.buttonsTextColor, for: .normal)
        button.backgroundColor = self.buttonsBackgroundColor
        button.titleLabel?.font = self.buttonsFont
        button.addTarget(self, action: #selector(GMStepper.leftButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpInside)
        button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpOutside)
        button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchCancel)
        return button
    }()
    
    lazy var rightButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.rightButtonText, for: .normal)
        button.setTitleColor(self.buttonsTextColor, for: .normal)
        button.backgroundColor = self.buttonsBackgroundColor
        button.titleLabel?.font = self.buttonsFont
        button.addTarget(self, action: #selector(GMStepper.rightButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpInside)
        button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchUpOutside)
        button.addTarget(self, action: #selector(GMStepper.buttonTouchUp), for: .touchCancel)
        return button
    }()
    
    lazy var label: UITextField = {
        let label = UITextField()
        label.textAlignment = .center
        label.text = formattedValue
        label.textColor = self.labelTextColor
        label.backgroundColor = self.labelBackgroundColor
        label.font = UIFont.systemFont(ofSize: 16)
        label.layer.cornerRadius = self.labelCornerRadius
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = viewStyle == .newInteractive || viewStyle == .normalInteractive
        label.delegate = self
        switch viewStyle {
        case .newInteractive,.normalInteractive:
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(GMStepper.handlePan))
            panRecognizer.maximumNumberOfTouches = 1
            label.addGestureRecognizer(panRecognizer)
            if #available(iOS 10.0, *) {
                label.keyboardType = .asciiCapableNumberPad
            } else {
                // Fallback on earlier versions
            }

        default:break
        }
  
        return label
    }()
    
    
    var font:UIFont  = UIFont.systemFont(ofSize: 16) {
        didSet {
            label.font = font
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        let oldValue = self.value
        if let text = textField.text, !text.isEmpty,
           let quantity = Double(text), quantity != oldValue {
            self.value = quantity <= 0 ? 1.0 : quantity
            sendActions(for: .valueChanged)
        } else {
            textField.text = Int(oldValue).description
        }
    }
    
    var labelOriginalCenter: CGPoint!
    var labelMaximumCenterX: CGFloat!
    var labelMinimumCenterX: CGFloat!
    
    enum LabelPanState {
        case Stable, HitRightEdge, HitLeftEdge
    }
    var panState = LabelPanState.Stable
    
    enum StepperState {
        case Stable, ShouldIncrease, ShouldDecrease
    }
    var stepperState = StepperState.Stable {
        didSet {
            if stepperState != .Stable {
                updateValue()
                if autorepeat {
                    scheduleTimer()
                }
            }
        }
    }
    
    
    @objc public var items : [String] = [] {
        didSet {
            label.text = formattedValue
        }
    }
    
    /// Timer used for autorepeat option
    var timer: Timer?
    
    /** When UIStepper reaches its top speed, it alters the value with a time interval of ~0.05 sec.
     The user pressing and holding on the stepper repeatedly:
     - First 2.5 sec, the stepper changes the value every 0.5 sec.
     - For the next 1.5 sec, it changes the value every 0.1 sec.
     - Then, every 0.05 sec.
     */
    let timerInterval = TimeInterval(0.05)
    
    /// Check the handleTimerFire: function. While it is counting the number of fires, it decreases the mod value so that the value is altered more frequently.
    var timerFireCount = 0
    var timerFireCountModulo: Int {
        if timerFireCount > 80 {
            return 1 // 0.05 sec * 1 = 0.05 sec
        } else if timerFireCount > 50 {
            return 2 // 0.05 sec * 2 = 0.1 sec
        } else {
            return 10 // 0.05 sec * 10 = 0.5 sec
        }
    }
    
    @objc required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    @objc public init(type:ViewStyle = .normal) {
        super.init(frame: .zero)
        self.viewStyle = type
        setup()
    }
   
    
    fileprivate func setup() {
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(label)
        
        if viewStyle == .normal || viewStyle == .normalInteractive {
            backgroundColor = buttonsBackgroundColor
        }
      
        switch viewStyle {
        case .normal,.normalInteractive:
            layer.cornerRadius = cornerRadius
            clipsToBounds = true
        case .new,.newInteractive:
            leftButton.layer.cornerRadius = cornerRadius
            leftButton.clipsToBounds = true
            rightButton.layer.cornerRadius = cornerRadius
            rightButton.clipsToBounds = true
        }
     
        labelOriginalCenter = label.center
        
        setupNumberFormatter()
        
        NotificationCenter.default.addObserver(self, selector: #selector(GMStepper.reset), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func setupNumberFormatter() {
        let decValue = Decimal(stepValue)
        let digits = decValue.significantFractionalDecimalDigits
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = showIntegerIfDoubleIsInteger ? 0 : digits
        formatter.maximumFractionDigits = digits
    }
    
    public override func layoutSubviews() {
        let buttonWidth =  bounds.size.width * ((1 - labelWidthWeight) / 2)
        let labelWidth = bounds.size.width * labelWidthWeight
        
        leftButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: bounds.size.height)
        label.frame = CGRect(x: buttonWidth, y: 0, width: labelWidth, height: bounds.size.height)
        rightButton.frame = CGRect(x: labelWidth + buttonWidth , y: 0, width: buttonWidth, height: bounds.size.height)
        
        labelMaximumCenterX = label.center.x + labelSlideLength
        labelMinimumCenterX = label.center.x - labelSlideLength
        labelOriginalCenter = label.center
    }
    
    func updateValue() {
        if stepperState == .ShouldIncrease {
            value += stepValue
            sendActions(for: .valueChanged)
        } else if stepperState == .ShouldDecrease {
            value -= stepValue
            sendActions(for: .valueChanged)
        }
    }
    
    
    deinit {
        resetTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    func leftButtonUpdateInterActions(){
        guard viewStyle == .new || viewStyle == .newInteractive else{return}
        leftButton.setTitleColor(value > 1 ? self.buttonsTextColor:disableColor, for: .normal)
        leftButton.isUserInteractionEnabled = value > 1
    }
    
    func rightButtonUpdateInterActions(){
        guard viewStyle == .new || viewStyle == .newInteractive else{return}
        let isOutOfStack = (value == 0 && value == maximumValue) || (value == maximumValue)
        rightButton.setTitleColor(!isOutOfStack ? self.buttonsTextColor:disableColor, for: .normal)
        rightButton.isUserInteractionEnabled = !isOutOfStack
    }
}

// MARK: Pan Gesture
extension GMStepper {
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            leftButton.isEnabled = false
            rightButton.isEnabled = false
        case .changed:
            let translation = gesture.translation(in: label)
            gesture.setTranslation(CGPoint.zero, in: label)
            
            let slidingRight = gesture.velocity(in: label).x > 0
            let slidingLeft = gesture.velocity(in: label).x < 0
            
            // Move the label with pan
            if slidingRight {
                label.center.x = min(labelMaximumCenterX, label.center.x + translation.x)
            } else if slidingLeft {
                label.center.x = max(labelMinimumCenterX, label.center.x + translation.x)
            }
            
            // When the label hits the edges, increase/decrease value and change button backgrounds
            if label.center.x == labelMaximumCenterX {
                // If not hit the right edge before, increase the value and start the timer. If already hit the edge, do nothing. Timer will handle it.
                if panState != .HitRightEdge {
                    stepperState = .ShouldIncrease
                    panState = .HitRightEdge
                }
                
                animateLimitHitIfNeeded()
            } else if label.center.x == labelMinimumCenterX {
                if panState != .HitLeftEdge {
                    stepperState = .ShouldDecrease
                    panState = .HitLeftEdge
                }
                
                animateLimitHitIfNeeded()
            } else {
                panState = .Stable
                stepperState = .Stable
                resetTimer()
                
                self.rightButton.backgroundColor = self.buttonsBackgroundColor
                self.leftButton.backgroundColor = self.buttonsBackgroundColor
            }
        case .ended, .cancelled, .failed:
            reset()
        default:
            break
        }
    }
    
    @objc func reset() {
        panState = .Stable
        stepperState = .Stable
        resetTimer()
        
        leftButton.isEnabled = true
        rightButton.isEnabled = true
        label.isUserInteractionEnabled = viewStyle == .newInteractive || viewStyle == .normalInteractive

        UIView.animate(withDuration: self.labelSlideDuration, animations: {
            self.label.center = self.labelOriginalCenter
            self.rightButton.backgroundColor = self.buttonsBackgroundColor
            self.leftButton.backgroundColor = self.buttonsBackgroundColor
        })
    }
}

// MARK: Button Events
extension GMStepper {
    @objc func leftButtonTouchDown(button: UIButton) {
        rightButton.isEnabled = false
        label.isUserInteractionEnabled = false
        resetTimer()
        
        if value == minimumValue {
            animateLimitHitIfNeeded()
        } else {
            stepperState = .ShouldDecrease
            animateSlideLeft()
        }
        
    }
    
    @objc func rightButtonTouchDown(button: UIButton) {
        leftButton.isEnabled = false
        label.isUserInteractionEnabled = false
        resetTimer()
        
        if value == maximumValue {
            animateLimitHitIfNeeded()
            self.onReachMaxValue?()
        } else {
            stepperState = .ShouldIncrease
            animateSlideRight()
        }
    }
    
    @objc func buttonTouchUp(button: UIButton) {
        reset()
    }
}

// MARK: Animations
extension GMStepper {
    
    func animateSlideLeft() {
        UIView.animate(withDuration: labelSlideDuration) {
            self.label.center.x -= self.labelSlideLength
        }
    }
    
    func animateSlideRight() {
        UIView.animate(withDuration: labelSlideDuration) {
            self.label.center.x += self.labelSlideLength
        }
    }
    
    func animateToOriginalPosition() {
        if self.label.center != self.labelOriginalCenter {
            UIView.animate(withDuration: labelSlideDuration) {
                self.label.center = self.labelOriginalCenter
            }
        }
    }
    
    func animateLimitHitIfNeeded() {
        if value == minimumValue {
            animateLimitHitForButton(button: leftButton)
        } else if value == maximumValue {
            animateLimitHitForButton(button: rightButton)
        }
    }
    
    func animateLimitHitForButton(button: UIButton){
        UIView.animate(withDuration: limitHitAnimationDuration) {
            button.backgroundColor = self.limitHitAnimationColor
        }
    }
}

// MARK: Timer
extension GMStepper {
    @objc func handleTimerFire(timer: Timer) {
        timerFireCount += 1
        
        if timerFireCount % timerFireCountModulo == 0 {
            updateValue()
        }
    }
    
    func scheduleTimer() {
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(GMStepper.handleTimerFire), userInfo: nil, repeats: true)
    }
    
    func resetTimer() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
            timerFireCount = 0
        }
    }
}


extension Decimal {
    var significantFractionalDecimalDigits: Int {
        return max(-exponent, 0)
    }
}

extension String {
    private static let formatter = NumberFormatter()
    
    func clippingCharacters(in characterSet: CharacterSet) -> String {
        components(separatedBy: characterSet).joined()
    }
    
    func convertedDigitsToLocale(_ locale: Locale = .current) -> String {
        let digits = Set(clippingCharacters(in: CharacterSet.decimalDigits.inverted))
        guard !digits.isEmpty else { return self }
        
        Self.formatter.locale = locale
        
        let maps: [(original: String, converted: String)] = digits.map {
            let original = String($0)
            let digit = Self.formatter.number(from: original)!
            let localized = Self.formatter.string(from: digit)!
            return (original, localized)
        }
        
        return maps.reduce(self) { converted, map in
            converted.replacingOccurrences(of: map.original, with: map.converted)
        }
    }
}
