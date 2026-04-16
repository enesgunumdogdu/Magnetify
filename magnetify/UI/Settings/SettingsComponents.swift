import SwiftUI

// MARK: - Hover Highlight Row

struct HoverHighlightRow<Content: View>: View {
    @State private var isHovered = false
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
            )
            .onHover { isHovered = $0 }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Shared Settings Components

func sectionHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .accessibilityAddTraits(.isHeader)
        Text(subtitle)
            .font(.callout)
            .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 8)
}

func settingsGroup<Content: View>(
    accentColor: Color = .clear,
    @ViewBuilder content: () -> Content
) -> some View {
    HStack(spacing: 0) {
        if accentColor != .clear {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentColor.gradient)
                .frame(width: 3)
                .padding(.vertical, 6)
        }

        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity)
    }
    .background(
        RoundedRectangle(cornerRadius: 10)
            .fill(.background)
            .shadow(color: .primary.opacity(0.06), radius: 1, y: 1)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(.quaternary, lineWidth: 1)
    )
    .padding(.horizontal, 16)
}

func toggleRow(
    icon: String,
    iconColor: Color,
    title: String,
    subtitle: String,
    isOn: Binding<Bool>
) -> some View {
    HoverHighlightRow {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

func sliderRow(
    icon: String,
    iconColor: Color,
    title: String,
    subtitle: String? = nil,
    value: Binding<Double>,
    range: ClosedRange<Double>,
    step: Double,
    unit: String,
    displayValue: String
) -> some View {
    HoverHighlightRow {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Slider(value: value, in: range, step: step)
                .frame(width: 120)
                .accessibilityLabel(title)
                .accessibilityValue("\(displayValue) \(unit)")

            Text(displayValue + unit)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

func iconBadge(_ name: String, color: Color) -> some View {
    Image(systemName: name)
        .font(.system(size: 11))
        .foregroundStyle(.white)
        .frame(width: 22, height: 22)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(color.gradient)
                .shadow(color: color.opacity(0.35), radius: 3, y: 1)
        )
}
