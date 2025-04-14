import 'package:get/get.dart';
import 'package:todo/db/db_helper.dart';
import 'package:todo/models/task.dart';
import 'package:intl/intl.dart';

class TaskController extends GetxController {
  final RxList<Task> taskList = <Task>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getTasks();
  }

  Future<int> addTask({Task? task}) async {
    try {
      isLoading.value = true;
      final result = await DBHelper.insert(task);
      if (result > 0) {
        print('Task added successfully with ID: $result');
        await getTasks(); // Refresh the task list after adding
      } else {
        print('Failed to add task, result code: $result');
      }
      return result;
    } catch (e) {
      print('Error in addTask: $e');
      return -1;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getTasks() async {
    try {
      isLoading.value = true;
      print('Getting tasks from database');
      final List<Map<String, dynamic>> tasks = await DBHelper.query();
      print('Retrieved ${tasks.length} tasks from database');
      
      if (tasks.isEmpty) {
        print('No tasks found in database');
        taskList.clear();
        return;
      }
      
      var tasksList = tasks.map((data) => Task.fromJson(data)).toList();
      
      // 根据任务的开始时间进行排序
      tasksList.sort((Task a, Task b) {
        if (a.date != b.date) {
          // 如果日期不同，则按日期排序
          // 使用 yMd 格式解析日期，例如 "7/10/2023"
          final DateFormat dateFormat = DateFormat.yMd();
          final DateTime aDate = dateFormat.parse(a.date!);
          final DateTime bDate = dateFormat.parse(b.date!);
          return aDate.compareTo(bDate);
        } else {
          // 如果日期相同，则按开始时间排序
          try {
            final DateFormat timeFormat = DateFormat('hh:mm a');
            final DateTime aTime = timeFormat.parse(a.startTime!);
            final DateTime bTime = timeFormat.parse(b.startTime!);
            return aTime.compareTo(bTime);
          } catch (e) {
            print('Error parsing time: $e');
            return 0;
          }
        }
      });
      
      print('Tasks sorted, assigning to taskList');
      taskList.assignAll(tasksList);
      print('Current task count: ${taskList.length}');
    } catch (e) {
      print('Error getting tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void deleteTasks(Task task) async {
    try {
      final result = await DBHelper.delete(task);
      if (result > 0) {
        print('Task deleted successfully: ${task.id}');
        await getTasks(); // Refresh the task list after deletion
      } else {
        print('Failed to delete task: ${task.id}');
      }
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  void deleteAllTasks() async {
    try {
      final result = await DBHelper.deleteAll();
      print('All tasks deleted: $result');
      await getTasks();
    } catch (e) {
      print('Error deleting all tasks: $e');
    }
  }

  void markTaskAsCompleted(int id) async {
    try {
      final result = await DBHelper.update(id);
      if (result > 0) {
        print('Task marked as completed: $id');
        await getTasks();
      } else {
        print('Failed to mark task as completed: $id');
      }
    } catch (e) {
      print('Error marking task as completed: $e');
    }
  }

  Future<int> editTask(Task task) async {
    try {
      isLoading.value = true;
      final result = await DBHelper.updateTask(task);
      if (result > 0) {
        print('Task updated successfully: ${task.id}');
        await getTasks();
      } else {
        print('Failed to update task: ${task.id}');
      }
      return result;
    } catch (e) {
      print('Error updating task: $e');
      return -1;
    } finally {
      isLoading.value = false;
    }
  }
}
