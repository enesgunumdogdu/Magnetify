import SwiftUI
import os

private let logger = Logger(subsystem: "com.example.magnetify", category: "OnboardingView")

struct OnboardingView: View {

    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStep: OnboardingStep = .welcome
    @State private var iconAppeared = false
    @State private var whyDisclosureExpanded = false
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            Group {
                switch currentStep {
                case .welcome:
                    welcomeStep
                case .accessibility:
                    accessibilityStep
                case .demo:
                    demoStep
                case .ready:
                    readyStep
                }
            }
            .id(currentStep)
            .transition(reduceMotion
                ? .opacity
                : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            // Swipe left → next
                            if currentStep != .ready {
                                if reduceMotion { currentStep = currentStep.next }
                                else { withAnimation(.easeInOut(duration: 0.3)) { currentStep = currentStep.next } }
                            }
                        } else if value.translation.width > 50 {
                            // Swipe right → previous
                            if currentStep != .welcome {
                                if reduceMotion { currentStep = currentStep.previous }
                                else { withAnimation(.easeInOut(duration: 0.3)) { currentStep = currentStep.previous } }
                            }
                        }
                    }
            )

            // Navigation
            HStack {
                if currentStep != .welcome {
                    Button(String(localized: "onboarding.back", defaultValue: "Back")) {
                        if reduceMotion { currentStep = currentStep.previous } else { withAnimation(.easeInOut(duration: 0.3)) { currentStep = currentStep.previous } }
                    }
                }

                Spacer()

                // Step indicators
                HStack(spacing: 6) {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        Circle()
                            .fill(step == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .accessibilityLabel(Text(
                                String(localized: "onboarding.step.accessibility \(step.rawValue + 1) \(OnboardingStep.allCases.count)")
                            ))
                            .accessibilityAddTraits(step == currentStep ? .isSelected : [])
                    }
                }

                Spacer()

                if currentStep == .ready {
                    Button(String(localized: "onboarding.getStarted", defaultValue: "Get Started")) {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                } else if currentStep == .accessibility && !accessibilityManager.isAccessibilityGranted {
                    Button(String(localized: "onboarding.grantAccess", defaultValue: "Grant Access")) {
                        accessibilityManager.requestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(String(localized: "onboarding.next", defaultValue: "Next")) {
                        if reduceMotion { currentStep = currentStep.next } else { withAnimation(.easeInOut(duration: 0.3)) { currentStep = currentStep.next } }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 520, height: 480)
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: .primary.opacity(0.15), radius: 6, y: 3)
                .scaleEffect(iconAppeared ? 1.0 : 0.8)
                .onAppear {
                    guard !reduceMotion else {
                        iconAppeared = true
                        return
                    }
                    withAnimation(.spring(response: 0.6)) {
                        iconAppeared = true
                    }
                }

            Text(String(localized: "onboarding.welcome.title", defaultValue: "Welcome to Magnetify"))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(String(localized: "onboarding.welcome.subtitle", defaultValue: "Organize your windows with drag, keyboard shortcuts, or menu bar — all for a one-time purchase."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }

    // MARK: - Accessibility Step

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: accessibilityManager.isAccessibilityGranted ? "checkmark.shield.fill" : "rectangle.and.hand.point.up.left.filled")
                .font(.system(size: 48))
                .foregroundStyle(accessibilityManager.isAccessibilityGranted ? Color.green : Color.accentColor)

            Text(String(localized: "onboarding.accessibility.title", defaultValue: "Enable Window Control"))
                .font(.title)
                .fontWeight(.semibold)

            Text(String(localized: "onboarding.accessibility.description", defaultValue: "Magnetify needs permission to move and resize windows. No data is collected — ever."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            if accessibilityManager.isAccessibilityGranted {
                Label(
                    String(localized: "onboarding.accessibility.granted", defaultValue: "Permission granted"),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)
                .font(.headline)
            }

            DisclosureGroup(
                String(localized: "onboarding.accessibility.whyNeeded", defaultValue: "Why is this needed?"),
                isExpanded: $whyDisclosureExpanded
            ) {
                Text(String(localized: "onboarding.accessibility.whyExplanation", defaultValue: "macOS requires apps to have Accessibility permission before they can move or resize windows that belong to other applications. This is an Apple security feature. Magnetify uses this permission solely to manage window positions — nothing else."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: 380)
        }
    }

    // MARK: - Demo Step

    private var demoStep: some View {
        VStack(spacing: 12) {
            Text(String(localized: "onboarding.demo.title", defaultValue: "How It Works"))
                .font(.title)
                .fontWeight(.semibold)

            // Visual snap zone grid mockup
            snapZoneGrid

            VStack(alignment: .leading, spacing: 10) {
                featureRow(
                    icon: "hand.draw",
                    title: String(localized: "onboarding.demo.drag.title", defaultValue: "Drag to Snap"),
                    description: String(localized: "onboarding.demo.drag.description", defaultValue: "Drag a window to the edge of your screen to snap it into position.")
                )

                featureRow(
                    icon: "keyboard",
                    title: String(localized: "onboarding.demo.keyboard.title", defaultValue: "Keyboard Shortcuts"),
                    description: String(localized: "onboarding.demo.keyboard.description", defaultValue: "Use Control + Option + Arrow keys for quick window snapping.")
                )

                featureRow(
                    icon: "menubar.rectangle",
                    title: String(localized: "onboarding.demo.menubar.title", defaultValue: "Menu Bar"),
                    description: String(localized: "onboarding.demo.menubar.description", defaultValue: "Click the menu bar icon to access all snap positions.")
                )

                featureRow(
                    icon: "square.stack.3d.up",
                    title: String(localized: "onboarding.demo.profiles.title", defaultValue: "Workspace Profiles"),
                    description: String(localized: "onboarding.demo.profiles.description", defaultValue: "Save and restore entire window layouts with a single click.")
                )
            }
            .frame(maxWidth: 400)
        }
    }

    // RTL note: the grid below represents physical screen positions and is decorative.
    private var snapZoneGrid: some View {
        VStack(spacing: 2) {
            // Top row: fullscreen indicator
            HStack(spacing: 2) {
                snapZoneCell(
                    String(localized: "onboarding.demo.zone.fullscreen", defaultValue: "Fullscreen"),
                    color: .blue
                )
            }
            .frame(height: 20)

            // Middle row: left half | quarters | right half
            HStack(spacing: 2) {
                // Left half (spanning two quarter rows visually as a single tall cell)
                snapZoneCell(
                    String(localized: "onboarding.demo.zone.leftHalf", defaultValue: "Left Half"),
                    color: .green
                )

                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        snapZoneCell(
                            String(localized: "onboarding.demo.zone.quarter", defaultValue: "Quarter"),
                            color: .orange
                        )
                        snapZoneCell(
                            String(localized: "onboarding.demo.zone.quarter", defaultValue: "Quarter"),
                            color: .orange
                        )
                    }
                    HStack(spacing: 2) {
                        snapZoneCell(
                            String(localized: "onboarding.demo.zone.quarter", defaultValue: "Quarter"),
                            color: .orange
                        )
                        snapZoneCell(
                            String(localized: "onboarding.demo.zone.quarter", defaultValue: "Quarter"),
                            color: .orange
                        )
                    }
                }

                snapZoneCell(
                    String(localized: "onboarding.demo.zone.rightHalf", defaultValue: "Right Half"),
                    color: .green
                )
            }
            .frame(height: 64)

            // Bottom row: thirds
            HStack(spacing: 2) {
                snapZoneCell(
                    String(localized: "onboarding.demo.zone.third", defaultValue: "Third"),
                    color: .purple
                )
                snapZoneCell(
                    String(localized: "onboarding.demo.zone.third", defaultValue: "Third"),
                    color: .purple
                )
                snapZoneCell(
                    String(localized: "onboarding.demo.zone.third", defaultValue: "Third"),
                    color: .purple
                )
            }
            .frame(height: 24)
        }
        .frame(width: 260)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
        )
        .accessibilityHidden(true)
    }

    private func snapZoneCell(_ label: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )

            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Ready Step

    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text(String(localized: "onboarding.ready.title", defaultValue: "You're All Set!"))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(String(localized: "onboarding.ready.subtitle", defaultValue: "Here are some quick ways to get started:"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            VStack(spacing: 10) {
                quickStartCard(
                    icon: "arrow.right.to.line",
                    title: String(localized: "onboarding.ready.tip.drag.title", defaultValue: "Drag any window to a screen edge"),
                    subtitle: String(localized: "onboarding.ready.tip.drag.subtitle", defaultValue: "It will snap into the matching zone automatically.")
                )

                quickStartCard(
                    icon: "keyboard",
                    title: String(localized: "onboarding.ready.tip.keyboard.title", defaultValue: "Use ⌃⌥← for left half"),
                    subtitle: String(localized: "onboarding.ready.tip.keyboard.subtitle", defaultValue: "Control + Option + Arrow keys snap windows instantly.")
                )

                quickStartCard(
                    icon: "menubar.rectangle",
                    title: String(localized: "onboarding.ready.tip.menubar.title", defaultValue: "Click the menu bar icon for all positions"),
                    subtitle: String(localized: "onboarding.ready.tip.menubar.subtitle", defaultValue: "Access every snap layout from the menu bar.")
                )
            }
            .frame(maxWidth: 400)
        }
    }

    private func quickStartCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.tint)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .primary.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.15), Color.primary.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case accessibility = 1
    case demo = 2
    case ready = 3

    var next: OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? self
    }

    var previous: OnboardingStep {
        OnboardingStep(rawValue: rawValue - 1) ?? self
    }
}
