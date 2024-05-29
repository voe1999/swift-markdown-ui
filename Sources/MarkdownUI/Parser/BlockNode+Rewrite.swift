import Foundation

public extension Sequence<BlockNode>
{
    func rewrite(_ r: (BlockNode) throws -> [BlockNode]) rethrows -> [BlockNode]
    {
        try flatMap { try $0.rewrite(r) }
    }

    func rewrite(_ r: (InlineNode) throws -> [InlineNode]) rethrows -> [BlockNode]
    {
        try flatMap { try $0.rewrite(r) }
    }
}

public extension BlockNode
{
    func rewrite(_ r: (BlockNode) throws -> [BlockNode]) rethrows -> [BlockNode]
    {
        switch self
        {
        case let .blockquote(children):
            return try r(.blockquote(children: children.rewrite(r)))
        case let .bulletedList(isTight, items):
            return try r(
                .bulletedList(
                    isTight: isTight,
                    items: try items.map
                    {
                        RawListItem(children: try $0.children.rewrite(r))
                    }
                )
            )
        case let .numberedList(isTight, start, items):
            return try r(
                .numberedList(
                    isTight: isTight,
                    start: start,
                    items: try items.map
                    {
                        RawListItem(children: try $0.children.rewrite(r))
                    }
                )
            )
        case let .taskList(isTight, items):
            return try r(
                .taskList(
                    isTight: isTight,
                    items: try items.map
                    {
                        RawTaskListItem(isCompleted: $0.isCompleted, children: try $0.children.rewrite(r))
                    }
                )
            )
        default:
            return try r(self)
        }
    }

    func rewrite(_ r: (InlineNode) throws -> [InlineNode]) rethrows -> [BlockNode]
    {
        switch self
        {
        case let .blockquote(children):
            return [.blockquote(children: try children.rewrite(r))]
        case let .bulletedList(isTight, items):
            return [
                .bulletedList(
                    isTight: isTight,
                    items: try items.map
                    {
                        RawListItem(children: try $0.children.rewrite(r))
                    }
                ),
            ]
        case let .numberedList(isTight, start, items):
            return [
                .numberedList(
                    isTight: isTight,
                    start: start,
                    items: try items.map
                    {
                        RawListItem(children: try $0.children.rewrite(r))
                    }
                ),
            ]
        case let .taskList(isTight, items):
            return [
                .taskList(
                    isTight: isTight,
                    items: try items.map
                    {
                        RawTaskListItem(isCompleted: $0.isCompleted, children: try $0.children.rewrite(r))
                    }
                ),
            ]
        case let .paragraph(content):
            return [.paragraph(content: try content.rewrite(r))]
        case let .heading(level, content):
            return [.heading(level: level, content: try content.rewrite(r))]
        case let .table(columnAlignments, rows):
            return [
                .table(
                    columnAlignments: columnAlignments,
                    rows: try rows.map
                    {
                        RawTableRow(
                            cells: try $0.cells.map
                            {
                                RawTableCell(content: try $0.content.rewrite(r))
                            }
                        )
                    }
                ),
            ]
        default:
            return [self]
        }
    }
}
