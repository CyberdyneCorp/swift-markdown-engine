import SwiftUI

// MARK: - Environment keys

private struct MarkdownThemeOverrideKey: EnvironmentKey {
    static let defaultValue: MarkdownTheme? = nil
}

private struct ResolvedMarkdownThemeKey: EnvironmentKey {
    static let defaultValue: MarkdownTheme = .light
}

private struct MarkdownConfigurationKey: EnvironmentKey {
    static let defaultValue: MarkdownConfiguration = .default
}

private struct MarkdownServicesKey: EnvironmentKey {
    static let defaultValue: MarkdownServices = .default
}

/// A handler invoked when an interactive task checkbox is toggled, carrying the
/// item's source range and the new checked state.
public struct TaskToggleHandler: Sendable {
    public let action: @Sendable (SourceRange?, Bool) -> Void
    public init(_ action: @escaping @Sendable (SourceRange?, Bool) -> Void) { self.action = action }
}

private struct TaskToggleHandlerKey: EnvironmentKey {
    static let defaultValue: TaskToggleHandler? = nil
}

extension EnvironmentValues {
    /// An explicit theme override set by the host, if any.
    var markdownThemeOverride: MarkdownTheme? {
        get { self[MarkdownThemeOverrideKey.self] }
        set { self[MarkdownThemeOverrideKey.self] = newValue }
    }

    /// The theme resolved for the current appearance; read by rendering subviews.
    var resolvedMarkdownTheme: MarkdownTheme {
        get { self[ResolvedMarkdownThemeKey.self] }
        set { self[ResolvedMarkdownThemeKey.self] = newValue }
    }

    /// The active configuration.
    var markdownConfiguration: MarkdownConfiguration {
        get { self[MarkdownConfigurationKey.self] }
        set { self[MarkdownConfigurationKey.self] = newValue }
    }

    /// The active services container.
    var markdownServices: MarkdownServices {
        get { self[MarkdownServicesKey.self] }
        set { self[MarkdownServicesKey.self] = newValue }
    }

    /// Handler invoked when an interactive checkbox is toggled.
    var markdownTaskToggleHandler: TaskToggleHandler? {
        get { self[TaskToggleHandlerKey.self] }
        set { self[TaskToggleHandlerKey.self] = newValue }
    }
}

// MARK: - Public modifiers

public extension View {
    /// Sets the Markdown theme for this view and its descendants. When unset, the
    /// engine picks `.light`/`.dark` based on the system appearance.
    func markdownTheme(_ theme: MarkdownTheme) -> some View {
        environment(\.markdownThemeOverride, theme)
    }

    /// Sets the Markdown configuration for this view and its descendants.
    func markdownConfiguration(_ configuration: MarkdownConfiguration) -> some View {
        environment(\.markdownConfiguration, configuration)
    }

    /// Sets the Markdown services for this view and its descendants.
    func markdownServices(_ services: MarkdownServices) -> some View {
        environment(\.markdownServices, services)
    }

    /// Registers a handler invoked when an interactive task checkbox is toggled.
    func markdownOnToggleTask(_ action: @escaping @Sendable (SourceRange?, Bool) -> Void) -> some View {
        environment(\.markdownTaskToggleHandler, TaskToggleHandler(action))
    }
}
