import SwiftUI

/// Simple four-function calculator widget.
struct CalculatorWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var display = "0"
    @State private var currentValue: Double = 0
    @State private var pendingOperation: Operation? = nil
    @State private var isEnteringNumber = false

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    enum Operation {
        case add, subtract, multiply, divide
    }

    var body: some View {
        VStack(spacing: XuloraSpacing.sm) {
            // Display
            HStack {
                Spacer()
                Text(display)
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .widgetContentPadding()

            // Keypad
            VStack(spacing: XuloraSpacing.xs) {
                calculatorRow(["C", "±", "%", "÷"], operations: [.none, .none, .none, .divide])
                calculatorRow(["7", "8", "9", "×"], operations: [.none, .none, .none, .multiply])
                calculatorRow(["4", "5", "6", "−"], operations: [.none, .none, .none, .subtract])
                calculatorRow(["1", "2", "3", "+"], operations: [.none, .none, .none, .add])
                calculatorRow(["0", "", ".", "="], operations: [.none, .none, .none, .none])
            }
            .padding(.horizontal, XuloraSpacing.md)
            .padding(.bottom, XuloraSpacing.md)
        }
        .background(WidgetBackground(appearance: appearance))
    }

    // MARK: Keypad

    private func calculatorRow(_ labels: [String], operations: [Operation?]) -> some View {
        HStack(spacing: XuloraSpacing.xs) {
            ForEach(0..<labels.count, id: \.self) { i in
                if labels[i].isEmpty {
                    Spacer().frame(maxWidth: .infinity)
                } else {
                    calculatorButton(labels[i], isOperation: operations[i] != nil) {
                        handleInput(labels[i], operation: operations[i])
                    }
                }
            }
        }
    }

    private func calculatorButton(_ label: String, isOperation: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: XuloraRadius.smallButton)
                        .fill(isOperation ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
                )
                .foregroundStyle(isOperation ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Logic

    private func handleInput(_ input: String, operation: Operation?) {
        switch input {
        case "0"..."9":
            enterDigit(input)
        case ".":
            enterDecimal()
        case "C":
            clear()
        case "±":
            negate()
        case "%":
            percentage()
        case "÷", "×", "−", "+":
            applyOperation(operation)
        case "=":
            computeResult()
        default:
            break
        }
    }

    private func enterDigit(_ digit: String) {
        if isEnteringNumber {
            display = display == "0" ? digit : display + digit
        } else {
            display = digit
            isEnteringNumber = true
        }
    }

    private func enterDecimal() {
        if isEnteringNumber {
            if !display.contains(".") {
                display += "."
            }
        } else {
            display = "0."
            isEnteringNumber = true
        }
    }

    private func clear() {
        display = "0"
        currentValue = 0
        pendingOperation = nil
        isEnteringNumber = false
    }

    private func negate() {
        guard let value = Double(display) else { return }
        display = formatNumber(-value)
    }

    private func percentage() {
        guard let value = Double(display) else { return }
        display = formatNumber(value / 100)
    }

    private func applyOperation(_ operation: Operation?) {
        guard let op = operation, let value = Double(display) else { return }

        if pendingOperation != nil {
            computeResult()
        }

        currentValue = value
        pendingOperation = op
        isEnteringNumber = false
    }

    private func computeResult() {
        guard let op = pendingOperation, let value = Double(display) else { return }

        let result: Double
        switch op {
        case .add:      result = currentValue + value
        case .subtract: result = currentValue - value
        case .multiply: result = currentValue * value
        case .divide:   result = value != 0 ? currentValue / value : currentValue
        }

        display = formatNumber(result)
        currentValue = result
        pendingOperation = nil
        isEnteringNumber = false
    }

    private func formatNumber(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return String(Int(value))
        }
        // Trim trailing zeros
        let str = String(format: "%.8f", value)
        let trimmed = str.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        return trimmed
    }
}
