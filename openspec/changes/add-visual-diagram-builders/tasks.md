## 1. Pie-chart builder

- [x] 1.1 Add `PieChartBuilder` view: title field + add/edit/remove slices (label + numeric value)
- [x] 1.2 Decompose a `pie` block into the model; serialize back to `pie title …` + `"label" : value`
- [x] 1.3 Route `pie` mermaid blocks to the builder in `WysiwygEditorView`

## 2. Flowchart builder

- [x] 2.1 Add `FlowchartBuilder` view: direction picker; add/edit/remove nodes (id, label, shape)
- [x] 2.2 Add/edit/remove edges (from, to, optional label)
- [x] 2.3 Decompose a `flowchart`/`graph` block into the model; serialize back to Mermaid
- [x] 2.4 Route `flowchart`/`graph` mermaid blocks to the builder in `WysiwygEditorView`

## 3. Verification

- [x] 3.1 Build PencilNotes; engine tests still green
- [x] 3.2 Add a UI test exercising a diagram builder (edit a flowchart/pie block)
- [x] 3.3 Run the iPad UI test suite (`scripts/test-pencilnotes-ipad.sh`) — all green
- [x] 3.4 `openspec validate add-visual-diagram-builders`
