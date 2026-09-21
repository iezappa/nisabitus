/// A node of the project tree.
class Project {
  Project({
    required this.id,
    required String name,
    this.parentId,
    this.description,
  }) : name = _validateName(name);

  final String id;
  final String name;
  final String? description;
  final String? parentId;

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

/// What the tasks of a project add up to, its subprojects included.
///
/// Four numbers rather than a single verdict, because the sidebar shows both
/// a colour and a figure and they are answers to different questions: how the
/// work stands, and how much of it there is.
typedef ProjectTally = ({int total, int done, int overdue, int dueToday});

/// How a project reads at a glance.
///
/// Ordered by what the user needs to know first: something is late, then
/// something is due today, then there is work open, then there is nothing
/// left, then there never was any. The sidebar dot is this, and only this —
/// a colour that meant two things would mean neither.
enum ProjectHealth { empty, allDone, open, dueToday, overdue }

extension ProjectTallyReading on ProjectTally {
  ProjectHealth get health {
    if (total == 0) return ProjectHealth.empty;
    if (overdue > 0) return ProjectHealth.overdue;
    if (dueToday > 0) return ProjectHealth.dueToday;
    if (done == total) return ProjectHealth.allDone;
    return ProjectHealth.open;
  }

  /// Finished share, 0 to 1. Zero for a project with no tasks, which the dot
  /// draws as an empty ring rather than a full one.
  double get progress => total == 0 ? 0 : done / total;
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

  final Map<String, Project> _byId;
  final List<String> _order;

  Iterable<Project> get all => _order.map((id) => _byId[id]!);

  /// Direct children of [parentId], or the roots when it is null.
  List<Project> childrenOf(String? parentId) =>
      all.where((project) => project.parentId == parentId).toList();

  /// Every project below [id], at any level.
  List<Project> descendantsOf(String id) => [
    for (final child in childrenOf(id)) ...[child, ...descendantsOf(child.id)],
  ];

  /// Level of [id]: one for a root, two for its children, and so on.
  int depthOf(String id) {
    var depth = 1;
    var current = _byId[id]?.parentId;
    while (current != null) {
      depth++;
      current = _byId[current]?.parentId;
    }
    return depth;
  }

  /// How many levels the branch rooted at [id] spans, itself included.
  int heightOf(String id) {
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
  bool canMove(String id, {required String? under}) {
    if (!_byId.containsKey(id)) return false;
    if (under == null) return heightOf(id) <= maxDepth;
    if (!_byId.containsKey(under)) return false;
    if (under == id) return false;
    if (descendantsOf(id).any((project) => project.id == under)) return false;

    return depthOf(under) + heightOf(id) <= maxDepth;
  }

  /// Whether a new child may be created under [parentId].
  bool canAddChild(String parentId) => depthOf(parentId) < maxDepth;

  /// Direct and inherited tallies for every project.
  ///
  /// A project answers for everything filed under it: a red dot on a parent
  /// is the only way an overdue task three levels down is visible without
  /// opening every branch.
  Map<String, ProjectTally> tallies(Map<String, ProjectTally> direct) {
    ProjectTally sum(ProjectTally a, ProjectTally b) => (
      total: a.total + b.total,
      done: a.done + b.done,
      overdue: a.overdue + b.overdue,
      dueToday: a.dueToday + b.dueToday,
    );

    const none = (total: 0, done: 0, overdue: 0, dueToday: 0);

    return {
      for (final project in all)
        project.id: descendantsOf(project.id).fold(
          direct[project.id] ?? none,
          (running, child) => sum(running, direct[child.id] ?? none),
        ),
    };
  }

  /// Direct and inherited task counts for every project.
  Map<String, TaskCount> taskCounts(Map<String, int> directCounts) => {
    for (final project in all)
      project.id: (
        direct: directCounts[project.id] ?? 0,
        descendants: descendantsOf(project.id)
            .fold(0, (sum, child) => sum + (directCounts[child.id] ?? 0)),
      ),
  };
}
