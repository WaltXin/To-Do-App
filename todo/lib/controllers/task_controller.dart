import 'package:get/get.dart';
import 'package:todo/db/db_helper.dart';
import 'package:todo/models/task.dart';
import 'package:intl/intl.dart';

class TaskController extends GetxController {
  final RxList<Task> taskList = <Task>[].obs;

  Future<int> addTask({Task? task}) {
    return DBHelper.insert(task);
  }

  Future<void> getTasks() async {
    final List<Map<String, dynamic>> tasks = await DBHelper.query();
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
    
    taskList.assignAll(tasksList);
  }

  void deleteTasks(Task task) async {
    await DBHelper.delete(task);
    getTasks();
  }

  void deleteAllTasks() async {
    await DBHelper.deleteAll();
    getTasks();
  }

  void markTaskAsCompleted(int id) async {
    await DBHelper.update(id);
    getTasks();
  }

  Future<int> editTask(Task task) async {
    final result = await DBHelper.updateTask(task);
    getTasks();
    return result;
  }
}
