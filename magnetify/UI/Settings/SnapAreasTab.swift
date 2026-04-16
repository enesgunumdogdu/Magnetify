import SwiftUI

struct SnapAreasPane: View {

    @ObservedObject private var store = CustomSnapAreaStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.snapAreas.title", defaultValue: "Custom Snap Areas"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(String(localized: "settings.snapAreas.subtitle", defaultValue: "Define custom screen regions for snapping. Drag a window to these areas or use the menu bar."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    let newArea = CustomSnapArea(
                        name: String(localized: "settings.snapAreas.defaultName", defaultValue: "New Area"),
                        rect: CodableRect(rect: CGRect(x: 0, y: 0, width: 0.5, height: 1.0))
                    )
                    store.addArea(newArea)
                } label: {
                    Label(
                        String(localized: "settings.snapAreas.add", defaultValue: "Add Area"),
                        systemImage: "plus"
                    )
                    .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)

            if store.areas.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text(String(localized: "settings.snapAreas.empty.title", defaultValue: "No Custom Areas"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(localized: "settings.snapAreas.empty.description", defaultValue: "No custom areas yet. Create a snap area to define exactly where you want windows to go."))
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 260)
                    Button {
                        let newArea = CustomSnapArea(
                            name: String(localized: "settings.snapAreas.defaultName", defaultValue: "New Area"),
                            rect: CodableRect(rect: CGRect(x: 0, y: 0, width: 0.5, height: 1.0))
                        )
                        store.addArea(newArea)
                    } label: {
                        Label(
                            String(localized: "settings.snapAreas.add", defaultValue: "Add Area"),
                            systemImage: "plus"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(store.areas) { area in
                            areaCard(area)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func areaCard(_ area: CustomSnapArea) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Mini preview
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 64, height: 40)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentColor.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                        )
                        .frame(
                            width: 64 * area.rect.width,
                            height: 40 * area.rect.height
                        )
                        .offset(
                            x: 64 * (area.rect.x - 0.5 + area.rect.width / 2),
                            y: 40 * (area.rect.y - 0.5 + area.rect.height / 2)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    TextField(String(localized: "settings.snapAreas.name", defaultValue: "Name"), text: Binding(
                        get: { area.name },
                        set: { newName in
                            var updated = area
                            updated.name = newName
                            store.updateArea(updated)
                        }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))

                    Text("X:\(String(format: "%.0f%%", area.rect.x * 100))  Y:\(String(format: "%.0f%%", area.rect.y * 100))  W:\(String(format: "%.0f%%", area.rect.width * 100))  H:\(String(format: "%.0f%%", area.rect.height * 100))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    store.snapToArea(area)
                } label: {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help(String(localized: "settings.snapAreas.apply", defaultValue: "Apply"))
                .accessibilityLabel(String(localized: "accessibility.snapAreas.apply", defaultValue: "Apply snap area"))

                Button(role: .destructive) {
                    store.deleteArea(id: area.id)
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(String(localized: "accessibility.snapAreas.delete", defaultValue: "Delete snap area"))
            }

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("X").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).frame(width: 14)
                    Slider(value: areaBinding(area, \.x), in: 0...0.9, step: 0.05)
                        .accessibilityLabel(String(localized: "accessibility.snapAreas.slider.x", defaultValue: "Horizontal position"))
                        .accessibilityValue(String(format: "%.0f%%", area.rect.x * 100))
                    Text("W").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).frame(width: 14)
                    Slider(value: areaBinding(area, \.width), in: 0.1...1.0, step: 0.05)
                        .accessibilityLabel(String(localized: "accessibility.snapAreas.slider.w", defaultValue: "Width"))
                        .accessibilityValue(String(format: "%.0f%%", area.rect.width * 100))
                }
                GridRow {
                    Text("Y").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).frame(width: 14)
                    Slider(value: areaBinding(area, \.y), in: 0...0.9, step: 0.05)
                        .accessibilityLabel(String(localized: "accessibility.snapAreas.slider.y", defaultValue: "Vertical position"))
                        .accessibilityValue(String(format: "%.0f%%", area.rect.y * 100))
                    Text("H").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary).frame(width: 14)
                    Slider(value: areaBinding(area, \.height), in: 0.1...1.0, step: 0.05)
                        .accessibilityLabel(String(localized: "accessibility.snapAreas.slider.h", defaultValue: "Height"))
                        .accessibilityValue(String(format: "%.0f%%", area.rect.height * 100))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .primary.opacity(0.06), radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private func areaBinding(_ area: CustomSnapArea, _ keyPath: WritableKeyPath<CodableRect, CGFloat>) -> Binding<CGFloat> {
        Binding(
            get: { area.rect[keyPath: keyPath] },
            set: { newValue in
                var updated = area
                var rect = updated.rect
                rect[keyPath: keyPath] = newValue
                updated.rect = rect
                store.updateArea(updated)
            }
        )
    }
}
