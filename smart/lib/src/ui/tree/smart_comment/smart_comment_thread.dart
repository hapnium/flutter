// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example usage of SmartCommentThread with a typical comment data structure.
/// 
/// ```dart
/// class CommentResponse {
///   final int id;
///   final String text;
///   final String author;
///   final String avatar;
///   final List<CommentResponse> replies;
///   final bool isCollapsed;
/// 
///   CommentResponse({
///     required this.id,
///     required this.text,
///     required this.author,
///     required this.avatar,
///     this.replies = const [],
///     this.isCollapsed = false,
///   });
/// }
/// 
/// // Usage in a widget
/// SmartCommentThread<CommentResponse>(
///   root: commentData,
///   childGetter: (comment) => comment.replies,
///   avatarBuilder: (context, comment) => PreferredSize(
///     preferredSize: Size.fromRadius(12),
///     child: CircleAvatar(
///       backgroundImage: NetworkImage(comment.avatar),
///       child: Text(comment.author[0]),
///     ),
///   ),
///   contentBuilder: (context, comment) => Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       Text(
///         comment.author,
///         style: TextStyle(fontWeight: FontWeight.bold),
///       ),
///       SizedBox(height: 4),
///       Text(comment.text),
///       SizedBox(height: 8),
///       Row(
///         children: [
///           TextButton(
///             onPressed: () => onLike(comment),
///             child: Text('Like'),
///           ),
///           TextButton(
///             onPressed: () => onReply(comment),
///             child: Text('Reply'),
///           ),
///         ],
///       ),
///     ],
///   ),
///   hideChildrenGetter: (comment) => comment.isCollapsed,
///   lineColor: Theme.of(context).primaryColor,
///   lineWidth: 2.0,
///   divider: 2.0,
/// )
/// ```
///
library;

import 'package:flutter/material.dart';
import 'package:smart/smart.dart';

import 'builders.dart';

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

/// A function type that builds avatar widgets for comment nodes.
/// 
/// **Parameters:**
/// - `context`: The build context for the widget
/// - `value`: The comment node data of type `Node`
/// 
/// **Returns:** A `PreferredSize` widget containing the avatar
/// 
/// **Usage:**
/// ```dart
/// AvatarWidgetBuilder<CommentResponse> avatarBuilder = (context, comment) {
///   return PreferredSize(
///     preferredSize: Size.fromRadius(12),
///     child: CircleAvatar(backgroundImage: NetworkImage(comment.avatar)),
///   );
/// };
/// ```
typedef AvatarWidgetBuilder<Node> = PreferredSize Function(BuildContext context, Node value);

/// A function type that builds content widgets for comment nodes.
/// 
/// **Parameters:**
/// - `context`: The build context for the widget
/// - `value`: The comment node data of type `Node`
/// 
/// **Returns:** A `Widget` containing the comment content
/// 
/// **Usage:**
/// ```dart
/// ContentBuilder<CommentResponse> contentBuilder = (context, comment) {
///   return Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       Text(comment.author, style: TextStyle(fontWeight: FontWeight.bold)),
///       Text(comment.text),
///     ],
///   );
/// };
/// ```
typedef ContentBuilder<Node> = Widget Function(BuildContext context, Node value);

/// A function type that extracts child comments from a parent comment node.
/// 
/// **Parameters:**
/// - `value`: The parent comment node of type `Node`
/// 
/// **Returns:** A `List<Node>` containing the child comments
/// 
/// **Usage:**
/// ```dart
/// ChildGetter<CommentResponse> childGetter = (comment) => comment.replies;
/// ```
typedef ChildGetter<Node> = List<Node> Function(Node value);

/// A function type that determines if children should be hidden for a comment node.
/// 
/// **Parameters:**
/// - `value`: The comment node of type `Node`
/// 
/// **Returns:** A `bool` indicating whether children should be hidden
/// 
/// **Usage:**
/// ```dart
/// HideChildrenGetter<CommentResponse> hideGetter = (comment) => comment.isCollapsed;
/// ```
typedef HideChildrenGetter<Node> = bool Function(Node value);

// ============================================================================
// MAIN WIDGET CLASS
// ============================================================================

/// A smart widget that creates a visually threaded comment system with connecting lines.
/// 
/// This widget supports:
/// - **Deep nesting**: Unlimited levels of nested comments
/// - **Visual connectors**: Curved lines connecting parent and child comments
/// - **RTL support**: Right-to-left text direction support
/// - **Customizable styling**: Colors, line widths, spacing, alignment
/// - **Hide/show functionality**: Ability to collapse comment threads
/// - **Responsive design**: Adapts to different screen sizes and orientations
/// 
/// **Type Parameters:**
/// - `Node`: The data type representing a comment (e.g., `CommentResponse`)
/// 
/// **Example Usage:**
/// ```dart
/// SmartCommentThread<CommentResponse>(
///   root: commentData,
///   childGetter: (comment) => comment.replies,
///   avatarBuilder: (context, comment) => PreferredSize(
///     preferredSize: Size.fromRadius(12),
///     child: CircleAvatar(backgroundImage: NetworkImage(comment.avatar)),
///   ),
///   contentBuilder: (context, comment) => CommentContent(comment: comment),
///   hideChildrenGetter: (comment) => comment.isCollapsed,
///   lineColor: Colors.blue,
///   lineWidth: 2.0,
/// )
/// ```
class SmartCommentThread<Node> extends SmartStateless {
  // --------------------------------------------------------------------------
  // REQUIRED FIELDS
  // --------------------------------------------------------------------------
  
  /// The root comment node to display at the top of the thread.
  /// 
  /// This is the main parent comment that will be rendered first,
  /// with all child comments nested beneath it.
  final Node root;

  /// Function that extracts child comments from any comment node.
  /// 
  /// This function is called recursively to build the entire comment tree.
  /// It should return an empty list if the comment has no replies.
  /// 
  /// **Example:**
  /// ```dart
  /// childGetter: (comment) => comment.replies ?? []
  /// ```
  final ChildGetter<Node> childGetter;

  /// Function that builds avatar widgets for any comment node.
  /// 
  /// Must return a `PreferredSize` widget to ensure consistent sizing
  /// across all comment levels.
  /// 
  /// **Example:**
  /// ```dart
  /// avatarBuilder: (context, comment) => PreferredSize(
  ///   preferredSize: Size.fromRadius(12),
  ///   child: CircleAvatar(backgroundImage: NetworkImage(comment.avatar)),
  /// )
  /// ```
  final AvatarWidgetBuilder<Node> avatarBuilder;

  /// Function that builds content widgets for any comment node.
  /// 
  /// This typically includes the comment text, author name, timestamp,
  /// and any action buttons (like, reply, etc.).
  /// 
  /// **Example:**
  /// ```dart
  /// contentBuilder: (context, comment) => Column(
  ///   crossAxisAlignment: CrossAxisAlignment.start,
  ///   children: [
  ///     Text(comment.author, style: TextStyle(fontWeight: FontWeight.bold)),
  ///     Text(comment.text),
  ///     Row(children: [LikeButton(), ReplyButton()]),
  ///   ],
  /// )
  /// ```
  final ContentBuilder<Node> contentBuilder;

  // --------------------------------------------------------------------------
  // OPTIONAL STYLING FIELDS
  // --------------------------------------------------------------------------

  /// Function that determines if children should be hidden for a comment.
  /// 
  /// If null, all children are always visible. If provided, children
  /// will be hidden when this function returns true for a comment.
  /// 
  /// **Default:** `null` (always show children)
  /// 
  /// **Example:**
  /// ```dart
  /// hideChildrenGetter: (comment) => comment.isCollapsed ?? false
  /// ```
  final HideChildrenGetter<Node>? hideChildrenGetter;

  /// The color of the connecting lines between comments.
  /// 
  /// **Default:** `Colors.grey`
  /// 
  /// **Example:**
  /// ```dart
  /// lineColor: Colors.blue
  /// ```
  final Color? lineColor;

  /// The width of the connecting lines in logical pixels.
  /// 
  /// **Default:** `1.5`
  /// 
  /// **Example:**
  /// ```dart
  /// lineWidth: 2.0
  /// ```
  final double? lineWidth;

  /// The divider value used for calculating line positions.
  /// 
  /// Lower values move lines closer to the avatar edge,
  /// higher values move them further away.
  /// 
  /// **Default:** `1.8`
  /// 
  /// **Range:** Typically between 1.0 and 3.0
  /// 
  /// **Example:**
  /// ```dart
  /// divider: 2.5  // Lines further from avatar
  /// ```
  final double? divider;

  // --------------------------------------------------------------------------
  // LAYOUT CONFIGURATION FIELDS
  // --------------------------------------------------------------------------

  /// How children should be aligned along the cross axis.
  /// 
  /// **Default:** `CrossAxisAlignment.start`
  /// 
  /// **Options:**
  /// - `CrossAxisAlignment.start`: Align to the start (left in LTR)
  /// - `CrossAxisAlignment.center`: Center alignment
  /// - `CrossAxisAlignment.end`: Align to the end (right in LTR)
  final CrossAxisAlignment? crossAxisAlignment;

  /// Vertical spacing between comment items in logical pixels.
  /// 
  /// **Default:** `0`
  /// 
  /// **Example:**
  /// ```dart
  /// spacing: 8.0  // 8 pixels between comments
  /// ```
  final double? spacing;

  /// How children should be aligned along the main axis.
  /// 
  /// **Default:** `MainAxisAlignment.start`
  final MainAxisAlignment? mainAxisAlignment;

  /// How much space the widget should occupy along the main axis.
  /// 
  /// **Default:** `MainAxisSize.min`
  final MainAxisSize? mainAxisSize;

  /// The text direction for the comment thread.
  /// 
  /// **Default:** `TextDirection.ltr`
  /// 
  /// **Options:**
  /// - `TextDirection.ltr`: Left-to-right (English, etc.)
  /// - `TextDirection.rtl`: Right-to-left (Arabic, Hebrew, etc.)
  final TextDirection? textDirection;

  /// The vertical direction for laying out children.
  /// 
  /// **Default:** `VerticalDirection.down`
  final VerticalDirection? verticalDirection;

  /// The text baseline for aligning text elements.
  /// 
  /// **Default:** `TextBaseline.alphabetic`
  final TextBaseline? textBaseline;

  // --------------------------------------------------------------------------
  // INTERNAL FIELDS (Private)
  // --------------------------------------------------------------------------

  /// Whether this instance represents a nested comment.
  /// 
  /// **Internal use only.** Used to differentiate between root-level
  /// and nested comment rendering.
  final bool _isNested;

  /// The current nesting level (0 = root, 1 = first level child, etc.).
  /// 
  /// **Internal use only.** Used for potential styling differences
  /// at different nesting levels.
  final int _nestingLevel;

  // --------------------------------------------------------------------------
  // CONSTRUCTORS
  // --------------------------------------------------------------------------

  /// Creates a new SmartCommentThread widget.
  /// 
  /// **Required Parameters:**
  /// - `root`: The root comment data
  /// - `childGetter`: Function to extract child comments
  /// - `avatarBuilder`: Function to build avatar widgets
  /// - `contentBuilder`: Function to build content widgets
  /// 
  /// **Optional Parameters:**
  /// - `hideChildrenGetter`: Function to determine if children should be hidden
  /// - `lineColor`: Color of connecting lines
  /// - `lineWidth`: Width of connecting lines
  /// - `divider`: Line position calculation factor
  /// - Layout and styling parameters
  /// 
  /// **Example:**
  /// ```dart
  /// SmartCommentThread<CommentResponse>(
  ///   root: myComment,
  ///   childGetter: (comment) => comment.replies,
  ///   avatarBuilder: (context, comment) => MyAvatar(comment),
  ///   contentBuilder: (context, comment) => MyContent(comment),
  /// )
  /// ```
  const SmartCommentThread({
    super.key,
    required this.root,
    required this.childGetter,
    required this.avatarBuilder,
    required this.contentBuilder,
    this.hideChildrenGetter,
    this.lineColor,
    this.lineWidth,
    this.divider,
    this.crossAxisAlignment,
    this.spacing,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
  }) : _isNested = false, _nestingLevel = 0;

  /// Internal constructor for creating nested comment instances.
  /// 
  /// **Private constructor.** Used internally by the widget to create
  /// nested comment threads recursively.
  const SmartCommentThread._nested({
    super.key,
    required this.root,
    required this.childGetter,
    required this.avatarBuilder,
    required this.contentBuilder,
    this.hideChildrenGetter,
    this.lineColor,
    this.lineWidth,
    this.divider,
    this.crossAxisAlignment,
    this.spacing,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
    required bool isNested,
    required int nestingLevel,
  }) : _isNested = isNested, _nestingLevel = nestingLevel;

  // --------------------------------------------------------------------------
  // WIDGET BUILD METHOD
  // --------------------------------------------------------------------------

  /// Builds the widget tree for the comment thread.
  /// 
  /// This method:
  /// 1. Extracts child comments using `childGetter`
  /// 2. Determines if children should be hidden using `hideChildrenGetter`
  /// 3. Builds the appropriate root or nested comment structure
  /// 4. Recursively creates child comment threads
  /// 
  /// **Parameters:**
  /// - `context`: The build context
  /// - `responsive`: Responsive utility for screen size calculations
  /// - `theme`: The current theme data
  /// 
  /// **Returns:** A `Widget` representing the complete comment thread
  @override
  Widget create(BuildContext context, ResponsiveUtil responsive, ThemeData theme) {
    // Extract avatar and calculate styling values
    final PreferredSize rootAvatar = avatarBuilder(context, root);
    final Color connectorColor = lineColor ?? Colors.grey;
    final double connectorWidth = lineWidth ?? 1.5;
    final double connectorDivider = divider ?? 1.8;
    
    // Get children and determine visibility
    final List<Node> children = childGetter(root);
    final bool hideChildren = hideChildrenGetter?.call(root) ?? false;

    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      spacing: spacing ?? 0,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      mainAxisSize: mainAxisSize ?? MainAxisSize.min,
      textDirection: textDirection ?? TextDirection.ltr,
      verticalDirection: verticalDirection ?? VerticalDirection.down,
      textBaseline: textBaseline ?? TextBaseline.alphabetic,
      children: [
        // Render root or nested comment
        if (_isNested)
          NestedCommentBuilder(
            avatar: rootAvatar,
            content: contentBuilder(context, root),
            lineColor: connectorColor,
            lineWidth: connectorWidth,
            divider: connectorDivider,
            nestingLevel: _nestingLevel,
            hasChildren: children.isNotEmpty && !hideChildren,
          )
        else
          RootBuilder(
            avatar: rootAvatar,
            content: contentBuilder(context, root),
            lineColor: connectorColor,
            lineWidth: connectorWidth,
            divider: connectorDivider,
            drawLine: children.isNotEmpty && !hideChildren,
          ),
        
        // Render children if they exist and are not hidden
        if (children.isNotEmpty && !hideChildren) ...[
          ...children.asMap().entries.map((entry) {
            int index = entry.key;
            Node child = entry.value;
            bool isLast = index == children.length - 1;
            
            return ChildBuilder(
              isLast: isLast,
              parentAvatarSize: rootAvatar.preferredSize,
              lineColor: connectorColor,
              lineWidth: connectorWidth,
              divider: connectorDivider,
              nestingLevel: _nestingLevel,
              child: SmartCommentThread<Node>._nested(
                root: child,
                childGetter: childGetter,
                avatarBuilder: avatarBuilder,
                contentBuilder: contentBuilder,
                hideChildrenGetter: hideChildrenGetter,
                lineColor: lineColor,
                lineWidth: lineWidth,
                divider: divider,
                crossAxisAlignment: crossAxisAlignment,
                spacing: spacing,
                mainAxisAlignment: mainAxisAlignment,
                mainAxisSize: mainAxisSize,
                textDirection: textDirection,
                verticalDirection: verticalDirection,
                textBaseline: textBaseline,
                isNested: true,
                nestingLevel: _nestingLevel + 1,
              ),
            );
          }),
        ]
      ],
    );
  }
}