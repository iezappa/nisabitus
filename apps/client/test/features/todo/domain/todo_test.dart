import 'package:flutter_test/flutter_test.dart';
import 'package:nisabit/features/todo/domain/project.dart';
import 'package:nisabit/features/todo/domain/task.dart';

void main() {
  group('TaskPriority.parse', () {
    test('accepts the canonical names and defaults to medium', () {
      expect(TaskPriority.parse('LOW'), TaskPriority.low);
      expect(TaskPriority.parse('urgent'), TaskPriority.urgent);
      expect(TaskPriority.parse(null), TaskPriority.medium);
    });

    test('rejects an unknown value', () {
      expect(() => TaskPriority.parse('BLOCKER'), throwsArgumentError);
    });

    test('orders from urgent down to low', () {
      final sorted = [...TaskPriority.values]
        ..sort((a, b) => a.rank.compareTo(b.rank));

      expect(sorted, [
        TaskPriority.urgent,
        TaskPriority.high,
        TaskPriority.medium,
        TaskPriority.low,
      ]);
    });
  });

  group('TaskStatus.parse', () {
    test('accepts the canonical names and defaults to todo', () {
      expect(TaskStatus.parse('IN_PROGRESS'), TaskStatus.inProgress);
      expect(TaskStatus.parse(null), TaskStatus.todo);
    });
  });

  group('Task.dueState', () {
    final today = DateTime(2026, 3, 11);

    Task task({DateTime? due, TaskStatus status = TaskStatus.todo}) => Task(
      id: 1,
      title: 'Escribir',
      projectId: 1,
      priority: TaskPriority.medium,
      status: status,
      dueDate: due,
    );

    test('is none without a due date', () {
      expect(task().dueState(today), DueState.none);
    });

    test('is overdue before today', () {
      expect(task(due: DateTime(2026, 3, 10)).dueState(today), DueState.overdue);
    });

    test('is due today on the day', () {
      expect(task(due: today).dueState(today), DueState.today);
    });

    test('is upcoming after today', () {
      expect(
        task(due: DateTime(2026, 3, 12)).dueState(today),
        DueState.upcoming,
      );
    });

    test('is none once the task is done, however late it was', () {
      // A finished task cannot be overdue; nagging about it helps nobody.
      expect(
        task(due: DateTime(2026, 1, 1), status: TaskStatus.done)
            .dueState(today),
        DueState.none,
      );
    });

    test('rejects a blank title', () {
      expect(
        () => Task(
          id: 1,
          title: '   ',
          projectId: 1,
          priority: TaskPriority.medium,
          status: TaskStatus.todo,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProjectTree', () {
    // root > child > grandchild, plus a second root.
    final projects = [
      Project(id: 1, name: 'Nísabit'),
      Project(id: 2, name: 'Módulos', parentId: 1),
      Project(id: 3, name: 'Hábitos', parentId: 2),
      Project(id: 4, name: 'Personal'),
    ];
    final tree = ProjectTree(projects);

    test('reports the depth of each node, roots being one', () {
      expect(tree.depthOf(1), 1);
      expect(tree.depthOf(2), 2);
      expect(tree.depthOf(3), 3);
    });

    test('lists the direct children in order', () {
      expect(tree.childrenOf(1).map((p) => p.id), [2]);
      expect(tree.childrenOf(null).map((p) => p.id), [1, 4]);
    });

    test('lists every descendant, not just the children', () {
      expect(tree.descendantsOf(1).map((p) => p.id), [2, 3]);
      expect(tree.descendantsOf(3), isEmpty);
    });

    test('knows how tall the branch under a node is', () {
      expect(tree.heightOf(1), 3);
      expect(tree.heightOf(2), 2);
      expect(tree.heightOf(3), 1);
    });
  });

  group('ProjectTree.canMove', () {
    final projects = [
      Project(id: 1, name: 'Nísabit'),
      Project(id: 2, name: 'Módulos', parentId: 1),
      Project(id: 3, name: 'Hábitos', parentId: 2),
      Project(id: 4, name: 'Personal'),
      Project(id: 5, name: 'Casa', parentId: 4),
    ];
    final tree = ProjectTree(projects);

    test('allows moving a leaf under a root', () {
      expect(tree.canMove(5, under: 1), isTrue);
    });

    test('allows detaching a node to the top level', () {
      expect(tree.canMove(3, under: null), isTrue);
    });

    test('refuses to move a project under itself', () {
      expect(tree.canMove(1, under: 1), isFalse);
    });

    test('refuses to move a project under its own descendant', () {
      // That would cut the branch loose from the tree entirely.
      expect(tree.canMove(1, under: 3), isFalse);
    });

    test('refuses a move that would make the branch four deep', () {
      // Node 4 holds a branch two tall; hanging it off node 2, already at
      // depth two, would reach depth four.
      expect(tree.canMove(4, under: 2), isFalse);
    });

    test('allows a move that lands exactly on the limit', () {
      expect(tree.canMove(5, under: 2), isTrue);
    });

    test('refuses to move a project under one that does not exist', () {
      expect(tree.canMove(5, under: 99), isFalse);
    });
  });

  group('ProjectTree counts', () {
    final tree = ProjectTree([
      Project(id: 1, name: 'Nísabit'),
      Project(id: 2, name: 'Módulos', parentId: 1),
    ]);

    test('separates direct tasks from those of the descendants', () {
      final counts = tree.taskCounts({1: 2, 2: 5});

      expect(counts[1]?.direct, 2);
      expect(counts[1]?.descendants, 5);
      expect(counts[1]?.total, 7);
      expect(counts[2]?.descendants, 0);
    });

    test('counts zero for a project nobody filed a task under', () {
      final counts = tree.taskCounts(const {});

      expect(counts[1]?.total, 0);
    });
  });
}
