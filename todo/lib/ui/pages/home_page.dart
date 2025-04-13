import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:todo/services/theme_services.dart';
import 'package:todo/ui/pages/add_task_page.dart';
import 'package:todo/ui/widgets/button.dart';
import 'package:todo/ui/widgets/task_tile.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../services/notification_services.dart';
import '../size_config.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NotifyHelper notifyHelper;
  bool _showVoiceButton = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.requestIOSPermissions();
    notifyHelper.initializeNotification();
    _taskController.getTasks();
  }

  DateTime _selectedDate = DateTime.now();
  int _weekOffset = 0;
  final TaskController _taskController = Get.put(TaskController());

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: darkGreyClr,
      appBar: _customAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _addTaskBar(),
              _addDateBar(),
              _showTasks(),
            ],
          ),
          if (_showVoiceButton) _buildVoiceButtonOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _customAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: darkGreyClr,
      toolbarHeight: 0,
      centerTitle: true,
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showMonthCalendar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Today',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white70,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  _addDateBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 20),
              child: Text(
                _currentWeekText(),
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _weekOffset = _weekOffset > 0 ? _weekOffset - 1 : 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _weekOffset > 0 ? Colors.grey[700] : Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: _weekOffset > 0 ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _weekOffset++;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = DateTime.now().add(Duration(days: index + (_weekOffset * 7)));
              final isSelected = _selectedDate.year == date.year && 
                                _selectedDate.month == date.month && 
                                _selectedDate.day == date.day;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 56) / 7,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryClr : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat('MMM').format(date).substring(0, 3),
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _currentWeekText() {
    final startDate = DateTime.now().add(Duration(days: _weekOffset * 7));
    final endDate = startDate.add(const Duration(days: 6));
    
    if (startDate.month == endDate.month) {
      return "${DateFormat('MMM').format(startDate)} ${startDate.day} - ${endDate.day}";
    } else {
      return "${DateFormat('MMM').format(startDate)} ${startDate.day} - ${DateFormat('MMM').format(endDate)} ${endDate.day}";
    }
  }

  Future<void> _onRefresh() async {
    _taskController.getTasks();
  }

  _showTasks() {
    return Expanded(
      child: Obx(() {
        if (_taskController.taskList.isEmpty) {
          return _noTaskMsg();
        } else {
          // 获取当前选中日期的任务列表
          final tasksForSelectedDate = _taskController.taskList.where((task) {
            // 检查任务是否应该在选定日期显示
            bool shouldShow = false;
            
            if (task.repeat == 'Daily') {
              shouldShow = true;
            } else if (task.repeat == 'Weekly') {
              shouldShow = _selectedDate
                  .difference(DateFormat.yMd().parse(task.date!))
                  .inDays %
                  7 ==
                  0;
            } else if (task.repeat == 'Monthly') {
              shouldShow = DateFormat.yMd().parse(task.date!).day ==
                  _selectedDate.day;
            } else {
              // 对于不重复的任务，只在确切日期显示
              var taskDate = DateFormat.yMd().parse(task.date!);
              shouldShow = taskDate.year == _selectedDate.year &&
                      taskDate.month == _selectedDate.month &&
                      taskDate.day == _selectedDate.day;
            }
            
            return shouldShow;
          }).toList();
          
          if (tasksForSelectedDate.isEmpty) {
            return _noTaskMsg();
          }
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              backgroundColor: darkGreyClr,
              color: primaryClr,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                scrollDirection: SizeConfig.orientation == Orientation.landscape
                    ? Axis.horizontal
                    : Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  var task = tasksForSelectedDate[index];
                  
                  try {
                    var date = DateFormat('hh:mm a').parse(task.startTime!.trim());
                    var myTime = DateFormat('HH:mm').format(date);

                    notifyHelper.scheduledNotification(
                      int.parse(myTime.toString().split(':')[0]),
                      int.parse(myTime.toString().split(':')[1]),
                      task,
                    );
                  } catch (e) {
                    print('Error parsing time: $e');
                  }

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 1375),
                    child: SlideAnimation(
                      horizontalOffset: 300,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () => _showBottomSheet(context, task),
                          child: _buildTimelineTask(task, index),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: tasksForSelectedDate.length,
              ),
            ),
          );
        }
      }),
    );
  }

  Widget _buildTimelineTask(Task task, int index) {
    // 计算任务持续时间
    var startTime = DateFormat('hh:mm a').parse(task.startTime!.trim());
    var endTime = DateFormat('hh:mm a').parse(task.endTime!.trim());
    final duration = endTime.difference(startTime);
    final durationMinutes = duration.inMinutes;
    final timeRange = '${task.startTime}-${task.endTime} (${durationMinutes} mins)';
    
    // 获取用于图标的颜色
    final bgColor = _getBGClr(task.color ?? 0);

    // 检查任务是否与其他任务重叠
    bool isOverlapping = _checkIfTaskOverlapping(task);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 左侧时间轴
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                task.startTime!.split(' ')[0], // 只显示时间，不显示AM/PM
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: isOverlapping ? 110 : 80,
                width: 0.8,
                color: Colors.grey[700],
              ),
            ],
          ),
          const SizedBox(width: 15),
          // 任务图标
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    task.title![0].toUpperCase(), // 显示任务名称的首字母
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (isOverlapping)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 5),
                  child: Text(
                    'Tasks are overlapping',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          // 任务详情
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeRange,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  task.title!,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                task.note!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          task.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
          // 右侧状态指示器
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: task.isCompleted == 1 ? Colors.green : bgColor,
                width: 2,
              ),
            ),
            child: task.isCompleted == 1
                ? const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 12,
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

  // 检查任务是否与其他任务重叠
  bool _checkIfTaskOverlapping(Task task) {
    // 获取当前选中日期的所有任务
    final tasksForSelectedDate = _taskController.taskList.where((t) {
      var taskDate = DateFormat.yMd().parse(t.date!);
      var selectedDate = DateFormat.yMd().parse(task.date!);
      return taskDate.year == selectedDate.year &&
             taskDate.month == selectedDate.month &&
             taskDate.day == selectedDate.day;
    }).toList();
    
    // 如果只有一个任务，则不存在重叠
    if (tasksForSelectedDate.length <= 1) {
      return false;
    }
    
    try {
      // 解析当前任务的开始和结束时间
      final DateFormat timeFormat = DateFormat('hh:mm a');
      final DateTime currentStart = timeFormat.parse(task.startTime!);
      final DateTime currentEnd = timeFormat.parse(task.endTime!);
      
      // 检查是否与其他任务重叠
      for (var otherTask in tasksForSelectedDate) {
        // 跳过当前任务自身
        if (otherTask.id == task.id) {
          continue;
        }
        
        final DateTime otherStart = timeFormat.parse(otherTask.startTime!);
        final DateTime otherEnd = timeFormat.parse(otherTask.endTime!);
        
        // 检查时间是否重叠
        // 重叠条件：一个任务的开始时间早于另一个任务的结束时间，且结束时间晚于另一个任务的开始时间
        if (currentStart.isBefore(otherEnd) && currentEnd.isAfter(otherStart)) {
          return true;
        }
      }
    } catch (e) {
      print('Error checking task overlap: $e');
    }
    
    return false;
  }

  Color _getBGClr(int no) {
    switch (no) {
      case 0:
        return bluishClr;
      case 1:
        return pinkClr;
      case 2:
        return orangeClr;
      default:
        return bluishClr;
    }
  }

  _noTaskMsg() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'images/task.svg',
              // ignore: deprecated_member_use
              color: primaryClr.withOpacity(0.7),
              height: 70,
              semanticsLabel: 'Task',
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'No Tasks Yet!',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add new tasks to make your days productive.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 25),
          InkWell(
            onTap: () async {
              await Get.to(() => AddTaskPage(initialDate: _selectedDate));
              _taskController.getTasks();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              decoration: BoxDecoration(
                color: primaryClr,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Task',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        width: SizeConfig.screenWidth,
        height: (SizeConfig.orientation == Orientation.landscape)
            ? (task.isCompleted == 1
                ? SizeConfig.screenHeight * 0.6
                : SizeConfig.screenHeight * 0.8)
            : (task.isCompleted == 1
                ? SizeConfig.screenHeight * 0.25
                : SizeConfig.screenHeight * 0.32),
        color: darkGreyClr,
        child: Column(
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[600],
              ),
              margin: const EdgeInsets.only(top: 10, bottom: 20),
            ),
            task.isCompleted == 1
                ? Container()
                : _buildBottomSheetButton(
                    label: 'Mark Complete',
                    onTap: () {
                      NotifyHelper().cancelNotification(task);
                      _taskController.markTaskAsCompleted(task.id!);
                      Get.back();
                    },
                    clr: primaryClr,
                    icon: Icons.check_circle_outline,
                  ),
            task.isCompleted == 1
                ? Container()
                : _buildBottomSheetButton(
                    label: 'Edit Task',
                    onTap: () async {
                      NotifyHelper().cancelNotification(task);
                      Get.back();
                      await Get.to(() => AddTaskPage(task: task));
                      _taskController.getTasks();
                    },
                    clr: Colors.green[400]!,
                    icon: Icons.edit,
                  ),
            _buildBottomSheetButton(
              label: 'Delete Task',
              onTap: () {
                NotifyHelper().cancelNotification(task);
                _taskController.deleteTasks(task);
                Get.back();
              },
              clr: Colors.red[400]!,
              icon: Icons.delete,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetButton({
    required String label,
    required Function() onTap,
    required Color clr,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: clr,
          ),
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 20),
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: darkGreyClr,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(
              icon: Icons.timeline,
              label: 'Timeline',
              onTap: () {
                setState(() {
                  _showVoiceButton = false;
                });
              },
              isActive: !_showVoiceButton,
            ),
            _buildNavButton(
              icon: Icons.mic,
              label: 'Voice',
              onTap: () {
                setState(() {
                  _showVoiceButton = !_showVoiceButton;
                });
              },
              isActive: _showVoiceButton,
            ),
            _buildNavButton(
              icon: Icons.settings,
              label: 'Setting',
              onTap: () {
                setState(() {
                  _showVoiceButton = false;
                });
                // Settings functionality can be added here
              },
            ),
            _buildNavButton(
              icon: Icons.add_circle,
              label: '',
              onTap: () async {
                setState(() {
                  _showVoiceButton = false;
                });
                await Get.to(() => AddTaskPage(initialDate: _selectedDate));
                _taskController.getTasks();
              },
              isMain: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMain ? 45 : 35,
            height: isMain ? 45 : 35,
            decoration: BoxDecoration(
              color: isMain ? primaryClr : isActive ? primaryClr.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(isMain ? 22.5 : 8),
            ),
            child: Icon(
              icon,
              color: isMain 
                  ? Colors.white 
                  : isActive 
                      ? primaryClr 
                      : Colors.white70,
              size: isMain ? 26 : 22,
            ),
          ),
          if (label.isNotEmpty)
            const SizedBox(height: 2),
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive 
                    ? primaryClr 
                    : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  // 显示日历选择器
  void _showMonthCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 420,
          decoration: BoxDecoration(
            color: darkGreyClr,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 15),
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMM().format(_selectedDate),
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month - 1,
                                1,
                              );
                              Navigator.pop(context);
                              _showMonthCalendar();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month + 1,
                                1,
                              );
                              Navigator.pop(context);
                              _showMonthCalendar();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 星期几标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                  ].map((day) => Text(
                    day,
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // 日历网格
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildCalendarGrid(),
                ),
              ),
              // Today 按钮
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _weekOffset = 0;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: primaryClr,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'Today',
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建日历网格
  Widget _buildCalendarGrid() {
    // 当前月份的第一天
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    // 当前月份的总天数
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    // 第一天是星期几 (1 = 周一, ..., 7 = 周日)
    int firstWeekday = firstDayOfMonth.weekday;
    // 因为我们的日历从周一开始，所以我们调整一下
    if (firstWeekday == 7) firstWeekday = 0;
    
    // 创建包含所有日期的列表
    List<Widget> dateWidgets = [];
    
    // 添加上个月的日期占位
    for (int i = 0; i < firstWeekday; i++) {
      dateWidgets.add(const SizedBox());
    }
    
    // 添加当前月的日期
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, i);
      final isSelected = date.year == _selectedDate.year &&
                       date.month == _selectedDate.month &&
                       date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
                     date.month == DateTime.now().month &&
                     date.day == DateTime.now().day;
      
      dateWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
              // 计算要设置的周偏移
              final daysSinceNow = date.difference(DateTime.now()).inDays;
              _weekOffset = (daysSinceNow / 7).floor();
            });
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? primaryClr : (isToday ? Colors.grey[700] : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                i.toString(),
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected || isToday ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // 计算行数
    int rowCount = (firstWeekday + daysInMonth) ~/ 7;
    if ((firstWeekday + daysInMonth) % 7 != 0) rowCount++;
    
    // 创建网格布局
    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dateWidgets,
    );
  }

  Widget _buildVoiceButtonOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 半透明背景，点击时关闭浮层
          GestureDetector(
            onTap: () {
              setState(() {
                _showVoiceButton = false;
              });
            },
            child: Container(
              color: Colors.black54,
            ),
          ),
          // 录音按钮定位在底部
          Positioned(
            bottom: 60, // 调整为100像素，位于底部导航栏上方
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: (){ /* 防止关闭弹窗 */ },
                    onLongPressStart: (_) {
                      setState(() {
                        _isRecording = true;
                      });
                    },
                    onLongPressEnd: (_) {
                      setState(() {
                        _isRecording = false;
                        _showVoiceButton = false; // 松开后关闭整个浮层
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryClr,
                        boxShadow: [
                          BoxShadow(
                            color: primaryClr.withOpacity(0.5),
                            spreadRadius: _isRecording ? 10 : 0,
                            blurRadius: _isRecording ? 15 : 0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: _isRecording ? 50 : 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Hold to Talk",
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isRecording) 
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildRecordingWaves(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingWaves() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 10.0 + (index * 5),
          width: 6,
          decoration: BoxDecoration(
            color: primaryClr,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
