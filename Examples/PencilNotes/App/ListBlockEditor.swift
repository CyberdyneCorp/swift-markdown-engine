import SwiftUI
import SwiftMarkdownEngine

/// Visual editor for a flat list block: switch between bulleted / numbered / checklist, edit
/// each item's text, toggle task checkboxes, and add/remove items — no Markdown markers shown.
/// Rebuilds the list's Markdown via `BlockNode.markdown()`. Nested lists keep the source editor.
struct ListBlockEditor: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    enum Style: String, CaseIterable, Identifiable { case bulleted = "Bulleted", numbered = "Numbered", checklist = "Checklist"; var id: String { rawValue } }

    struct Item: Identifiable, Equatable {
        let id = UUID()
        var text: String
        var checked: Bool
    }

    @State private var style: Style = .bulleted
    @State private var items: [Item] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("List style", selection: $style) {
                ForEach(Style.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)

            ForEach($items) { $item in
                HStack(spacing: 8) {
                    leadingMarker($item)
                    TextField("Item", text: $item.text)
                        .padding(6)
                        .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
                    Button(role: .destructive) { remove(item.id) } label: { Image(systemName: "trash") }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Delete item")
                }
            }

            Button { addItem() } label: { Label("Item", systemImage: "plus") }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accent)
                .font(.system(size: 15, weight: .medium))
        }
        .onAppear(perform: decompose)
        .onChange(of: items) { _ in recompose() }
        .onChange(of: style) { _ in recompose() }
    }

    @ViewBuilder
    private func leadingMarker(_ item: Binding<Item>) -> some View {
        switch style {
        case .bulleted:
            Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(theme.textSecondary).frame(width: 22)
        case .numbered:
            Text("\((items.firstIndex { $0.id == item.wrappedValue.id } ?? 0) + 1).")
                .foregroundStyle(theme.textSecondary).frame(width: 22)
        case .checklist:
            Button { item.wrappedValue.checked.toggle() } label: {
                Image(systemName: item.wrappedValue.checked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(item.wrappedValue.checked ? theme.accent : theme.textSecondary)
            }
            .buttonStyle(.plain)
            .frame(width: 22)
            .accessibilityLabel(item.wrappedValue.checked ? "Checked" : "Unchecked")
        }
    }

    // MARK: - Mutations

    private func addItem() { items.append(Item(text: "", checked: false)) }
    private func remove(_ id: UUID) { items.removeAll { $0.id == id } }

    // MARK: - Markdown <-> model

    private func decompose() {
        guard case .list(let list)? = MarkdownParser().parse(markdown).blocks.first?.kind else { return }
        let isTask = list.items.contains { $0.checkbox != nil }
        if isTask { style = .checklist }
        else if case .ordered = list.marker { style = .numbered }
        else { style = .bulleted }

        items = list.items.map { item in
            Item(text: Self.itemText(item.blocks), checked: item.checkbox == .checked)
        }
    }

    private func recompose() {
        let marker: MarkdownList.Marker = (style == .numbered) ? .ordered(start: 1) : .bullet
        let modelItems = items.map { item -> ListItem in
            let checkbox: ListItem.Checkbox? = (style == .checklist) ? (item.checked ? .checked : .unchecked) : nil
            return ListItem(blocks: [BlockNode(.paragraph(Self.inlines(item.text)))], checkbox: checkbox)
        }
        markdown = BlockNode(.list(MarkdownList(marker: marker, isTight: true, items: modelItems))).markdown()
    }

    private static func itemText(_ blocks: [BlockNode]) -> String {
        guard case .paragraph(let nodes)? = blocks.first?.kind else { return "" }
        return nodes.map { $0.markdown() }.joined().trimmingCharacters(in: .whitespaces)
    }

    private static func inlines(_ s: String) -> [InlineNode] {
        guard case .paragraph(let nodes)? = MarkdownParser().parse(s).blocks.first?.kind else {
            return s.isEmpty ? [] : [InlineNode(.text(s))]
        }
        return nodes
    }
}
