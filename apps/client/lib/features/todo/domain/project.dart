/// A node of the project tree.
class Project {
  Project({
    required this.id,
    required String name,
    this.parentId,
    this.description,
  }) : name = _validateName(name);

  final int id;
  final String name;
  final String? description;
  final int? parentId;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }
}

/// Tasks filed directly on a project, and those under everything below it.
typedef TaskCount = ({int direct, int descendants});

extension TaskCountTotal on TaskCount {
  int get total => direct + descendants;
}

/// The project hierarchy and the rules that keep it a tree.
///
/// Built from a flat list because that is how the store holds it; every
/// question about shape is answered here rather than in the UI.
class ProjectTree {
  ProjectTree(List<Project> projects)
    : _byId = {for (final project in projects) project.id: project},
      _order = [for (final project in projects) project.id];

  /// How deep the hierarchy may go, counting a root as level one.
  static const maxDepth = 3;

  final Map<int, Project> _byId;
  final List<int> _order;

  Iterable<Project> get all => _order.map((id) => _byId[id]!);

  /// Direct children of [parentId], or the roots when it is null.
  List<Project> childrenOf(int? parentId) =>
      all.where((project) => project.parentId == parentId).toList();

  /// Every project below [id], at any level.
  List<Project> descendantsOf(int id) => [
    for (final child in childrenOf(id)) ...[child, ...descendantsOf(child.id)],
  ];

  /// Level of [id]: one for a root, two for its children, and so on.
  int depthOf(int id) {
    var depth = 1;
    var current = _byId[id]?.parentId;
    while (current != null) {
      depth++;
      current = _byId[current]?.parentId;
    }
    return depth;
  }

  /// How many levels the branch rooted at [id] spans, itself included.
  int heightOf(int id) {
    final children = childrenOf(id);
    if (children.isEmpty) return 1;

    return 1 +
        children
            .map((child) => heightOf(child.id))
            .reduce((a, b) => a > b ? a : b);
  }

  /// Whether [id] may be reparented under [under].
  ///
  /// Three ways this fails: hanging a project off itself, off one of its own
  /// descendants — which would cut the branch loose from the tree — or
  /// somewhere that would push the resulting branch past [maxDepth].
  bool canMove(int id, {required int? under}) {
    if (!_byId.containsKey(id)) return false;
    if (under == null) return heightOf(id) <= maxDepth;
    if (!_byId.containsKey(under)) return false;
    if (under == id) return false;
    if (descendantsOf(id).any((project) => project.id == under)) return false;

    return depthOf(under) + heightOf(id) <= maxDepth;
  }

  /// Whether a new child may be created under [parentId].
  bool canAddChild(int parentId) => depthOf(parentId) < maxDepth;

  /// Direct and inherited task counts for every project.
  Map<int, TaskCount> taskCounts(Map<int, int> directCounts) => {
    for (final project in all)
      project.id: (
        direct: directCounts[project.id] ?? 0,
        descendants: descendantsOf(project.id)
            .fold(0, (sum, child) => sum + (directCounts[child.id] ?? 0)),
      ),
  };
}
