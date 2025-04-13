import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/task_controller.dart';
import 'package:todo/ui/theme.dart';
import '../../models/task.dart';
import 'dart:async';

class AddTaskPage extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;
  const AddTaskPage({Key? key, this.task, this.initialDate}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskController _taskController = Get.put(TaskController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  late DateTime _selectedDate;
  late String _startTime;
  late String _endTime;
  
  int _selectedRemind = 5;
  List<int> remindList = [5, 10, 15, 20];
  String _selectedRepeat = 'None';
  List<String> repeatList = ['None', 'Daily', 'Weekly', 'Monthly'];
  int _selectedColor = 0;
  
  final List<Color> _colorList = [
    const Color(0xFFFF9AA2), // Pink
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.teal,
    Colors.purple,
  ];

  final List<int> _durationOptions = [15, 30, 45, 60, 90]; // in minutes

  // Add these variables for calendar view
  bool _showCalendar = false;
  String _currentMonth = '';

  // Add a variable to keep track of the selected time slot
  int _selectedTimeIndex = -1;

  // Add a variable to track time range display format
  bool _showTimeRange = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title!;
      _noteController.text = widget.task!.note!;
      _selectedDate = DateFormat.yMd().parse(widget.task!.date!);
      _startTime = widget.task!.startTime!;
      _endTime = widget.task!.endTime!;
      _selectedRemind = widget.task!.remind!;
      _selectedRepeat = widget.task!.repeat!;
      _selectedColor = widget.task!.color!;
      
      // 编辑任务时，设置选中状态以便正确显示时间框
      _selectedTimeIndex = 0; // 默认选中第一个时间框
      _showTimeRange = true;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _startTime = DateFormat('hh:mm a').format(DateTime.now()).toString();
      // Set end time 15 minutes after start time by default
      final endTime = DateTime.now().add(const Duration(minutes: 15));
      _endTime = DateFormat('hh:mm a').format(endTime);
      // Set default selected remind to 15 minutes
      _selectedRemind = 15;
    }
    _updateCurrentMonth();
  }
  
  void _updateCurrentMonth() {
    _currentMonth = DateFormat('MMMM yyyy').format(_selectedDate);
  }

  // Add this method to calculate end time based on start time and duration
  void _updateEndTime() {
    // Parse the start time
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime startDateTime = format.parse(_startTime);
    
    // Add the selected duration to get the end time
    final DateTime endDateTime = startDateTime.add(Duration(minutes: _selectedRemind));
    
    // Format the end time
    _endTime = DateFormat('hh:mm a').format(endDateTime);
  }
  
  // Add this method to get formatted time range
  String _getTimeRange() {
    // Extract just time without AM/PM for start time
    String start = _startTime.split(' ')[0];
    
    // Extract time and period for end time
    List<String> endParts = _endTime.split(' ');
    String end = endParts[0];
    String period = endParts[1];
    
    // If start and end have same period (AM/PM), only show it once at the end
    if (_startTime.contains(period)) {
      return '$start–$end $period';
    } else {
      // If periods are different, show both
      String startPeriod = _startTime.split(' ')[1];
      return '$start $startPeriod–$end $period';
    }
  }

  // 添加方法用于计算任务持续时间（分钟）
  int _calculateDurationInMinutes() {
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime startDateTime = format.parse(_startTime);
    final DateTime endDateTime = format.parse(_endTime);
    
    // 计算分钟差
    final int minutes = endDateTime.difference(startDateTime).inMinutes;
    return minutes;
  }
  
  // Add this method to show time picker dialog
  Future<bool> _showTimePickerDialog({required bool isStartTime}) {
    // Create a Completer to handle asynchronous result
    final completer = Completer<bool>();
    
    // Use a variable to track which is currently being edited (start time or end time)
    bool _editingStartTime = isStartTime;
    
    // 创建控制器供滚轮使用
    FixedExtentScrollController? hourController;
    FixedExtentScrollController? minuteController;
    FixedExtentScrollController? periodController;
    
    // 直接初始化控制器（对话框第一次显示时）
    // 获取当前时间
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime initialTime = format.parse(isStartTime ? _startTime : _endTime);
    
    // 小时 (1-12)
    final int hour12 = initialTime.hour > 12 ? initialTime.hour - 12 : (initialTime.hour == 0 ? 12 : initialTime.hour);
    final String hour12String = hour12.toString().padLeft(2, '0');
    final hourIndex = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0')).indexOf(hour12String);
    hourController = FixedExtentScrollController(initialItem: hourIndex != -1 ? hourIndex : 0);
    
    // 分钟 (00-59)
    final String minuteString = initialTime.minute.toString().padLeft(2, '0');
    final minuteIndex = List.generate(60, (i) => i.toString().padLeft(2, '0')).indexOf(minuteString);
    minuteController = FixedExtentScrollController(initialItem: minuteIndex != -1 ? minuteIndex : 0);
    
    // 时段 (AM/PM)
    final isPM = initialTime.hour >= 12;
    periodController = FixedExtentScrollController(initialItem: isPM ? 1 : 0);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: darkGreyClr,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Parse the current selected time
            final DateFormat format = DateFormat('hh:mm a');
            DateTime selectedStartTime = format.parse(_startTime);
            DateTime selectedEndTime = format.parse(_endTime);
            
            // Calculate task duration
            int durationMinutes = _calculateDurationInMinutes();
            
            return Container(
              height: 470, // Further reduce overall height
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.pop(context);
                        completer.complete(false); // User closes dialog, returns false
                      },
                    ),
                  ),
                  
                  // Display task duration
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5), // Reduce vertical padding
                    child: Text(
                      "This task takes $durationMinutes mins.",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22, // Reduce font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Start and end time picker switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Start time button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // 先设置状态为编辑开始时间
                            setState(() {
                              _editingStartTime = true;
                            });
                            
                            // 一定要先释放旧的控制器
                            hourController?.dispose();
                            minuteController?.dispose();
                            periodController?.dispose();
                            
                            // 解析开始时间
                            final DateFormat format = DateFormat('hh:mm a');
                            final DateTime startDateTime = format.parse(_startTime);
                            
                            // 重新创建控制器，确保它们指向正确的初始位置
                            // 小时 (1-12)
                            final int hour12 = startDateTime.hour > 12 ? startDateTime.hour - 12 : (startDateTime.hour == 0 ? 12 : startDateTime.hour);
                            final String hour12String = hour12.toString().padLeft(2, '0');
                            final hourIndex = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0')).indexOf(hour12String);
                            
                            // 分钟 (00-59)
                            final String minuteString = startDateTime.minute.toString().padLeft(2, '0');
                            final minuteIndex = List.generate(60, (i) => i.toString().padLeft(2, '0')).indexOf(minuteString);
                            
                            // 时段 (AM/PM)
                            final isPM = startDateTime.hour >= 12;
                            
                            // 等待下一帧再创建控制器，确保视图已经更新
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // 因为上面已经释放了旧控制器，这里需要在下一帧再创建新的
                              hourController = FixedExtentScrollController(initialItem: hourIndex != -1 ? hourIndex : 0);
                              minuteController = FixedExtentScrollController(initialItem: minuteIndex != -1 ? minuteIndex : 0);
                              periodController = FixedExtentScrollController(initialItem: isPM ? 1 : 0);
                              
                              // 再次更新UI以刷新滚轮位置
                              setState(() {});
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8), // Reduce padding
                            decoration: BoxDecoration(
                              color: _editingStartTime ? _colorList[_selectedColor] : Colors.grey[800],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Start",
                                  style: TextStyle(
                                    color: _editingStartTime ? Colors.white : Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startTime,
                                  style: TextStyle(
                                    color: _editingStartTime ? Colors.white : Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // End time button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // 先设置状态为编辑结束时间
                            setState(() {
                              _editingStartTime = false;
                            });
                            
                            // 一定要先释放旧的控制器
                            hourController?.dispose();
                            minuteController?.dispose();
                            periodController?.dispose();
                            
                            // 解析结束时间
                            final DateFormat format = DateFormat('hh:mm a');
                            final DateTime endDateTime = format.parse(_endTime);
                            
                            // 重新创建控制器，确保它们指向正确的初始位置
                            // 小时 (1-12)
                            final int hour12 = endDateTime.hour > 12 ? endDateTime.hour - 12 : (endDateTime.hour == 0 ? 12 : endDateTime.hour);
                            final String hour12String = hour12.toString().padLeft(2, '0');
                            final hourIndex = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0')).indexOf(hour12String);
                            
                            // 分钟 (00-59)
                            final String minuteString = endDateTime.minute.toString().padLeft(2, '0');
                            final minuteIndex = List.generate(60, (i) => i.toString().padLeft(2, '0')).indexOf(minuteString);
                            
                            // 时段 (AM/PM)
                            final isPM = endDateTime.hour >= 12;
                            
                            // 等待下一帧再创建控制器，确保视图已经更新
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // 因为上面已经释放了旧控制器，这里需要在下一帧再创建新的
                              hourController = FixedExtentScrollController(initialItem: hourIndex != -1 ? hourIndex : 0);
                              minuteController = FixedExtentScrollController(initialItem: minuteIndex != -1 ? minuteIndex : 0);
                              periodController = FixedExtentScrollController(initialItem: isPM ? 1 : 0);
                              
                              // 再次更新UI以刷新滚轮位置
                              setState(() {});
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8), // Reduce padding
                            decoration: BoxDecoration(
                              color: !_editingStartTime ? _colorList[_selectedColor] : Colors.grey[800],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "End",
                                  style: TextStyle(
                                    color: !_editingStartTime ? Colors.white : Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endTime,
                                  style: TextStyle(
                                    color: !_editingStartTime ? Colors.white : Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10), // Reduce spacing
                  
                  // Time picker
                  Container(
                    height: 130, // Reduce height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour picker
                        Expanded(
                          child: Container(
                            height: 130,
                            child: ListWheelScrollView.useDelegate(
                              controller: hourController,
                              itemExtent: 28, // Reduce item height
                              perspective: 0.005,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                final items = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
                                final newHour = int.parse(items[index]);
                                
                                // 获取当前编辑的时间
                                DateTime time = _editingStartTime ? selectedStartTime : selectedEndTime;
                                final isPM = time.hour >= 12;
                                final adjustedHour = isPM ? (newHour == 12 ? 12 : newHour + 12) : (newHour == 12 ? 0 : newHour);
                                
                                if (_editingStartTime) {
                                  selectedStartTime = DateTime(
                                    selectedStartTime.year,
                                    selectedStartTime.month,
                                    selectedStartTime.day,
                                    adjustedHour,
                                    selectedStartTime.minute,
                                  );
                                  _startTime = DateFormat('hh:mm a').format(selectedStartTime);
                                } else {
                                  selectedEndTime = DateTime(
                                    selectedEndTime.year,
                                    selectedEndTime.month,
                                    selectedEndTime.day,
                                    adjustedHour,
                                    selectedEndTime.minute,
                                  );
                                  _endTime = DateFormat('hh:mm a').format(selectedEndTime);
                                }
                                
                                // Update displayed duration
                                durationMinutes = _calculateDurationInMinutes();
                                setState(() {});
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 12,
                                builder: (context, index) {
                                  final items = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
                                  return Center(
                                    child: Text(
                                      items[index],
                                      style: TextStyle(
                                        color: hourController?.selectedItem == index ? _colorList[_selectedColor] : Colors.white70,
                                        fontSize: hourController?.selectedItem == index ? 20 : 16,
                                        fontWeight: hourController?.selectedItem == index ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Separator
                        Text(
                          ":",
                          style: TextStyle(
                            color: _colorList[_selectedColor],
                            fontSize: 30, // Reduce font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        // Minute picker
                        Expanded(
                          child: Container(
                            height: 130,
                            child: ListWheelScrollView.useDelegate(
                              controller: minuteController,
                              itemExtent: 28, // Reduce item height
                              perspective: 0.005,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                final items = List.generate(60, (i) => i.toString().padLeft(2, '0'));
                                final newMinute = int.parse(items[index]);
                                
                                if (_editingStartTime) {
                                  selectedStartTime = DateTime(
                                    selectedStartTime.year,
                                    selectedStartTime.month,
                                    selectedStartTime.day,
                                    selectedStartTime.hour,
                                    newMinute,
                                  );
                                  _startTime = DateFormat('hh:mm a').format(selectedStartTime);
                                } else {
                                  selectedEndTime = DateTime(
                                    selectedEndTime.year,
                                    selectedEndTime.month,
                                    selectedEndTime.day,
                                    selectedEndTime.hour,
                                    newMinute,
                                  );
                                  _endTime = DateFormat('hh:mm a').format(selectedEndTime);
                                }
                                
                                // Update displayed duration
                                durationMinutes = _calculateDurationInMinutes();
                                setState(() {});
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  final items = List.generate(60, (i) => i.toString().padLeft(2, '0'));
                                  return Center(
                                    child: Text(
                                      items[index],
                                      style: TextStyle(
                                        color: minuteController?.selectedItem == index ? _colorList[_selectedColor] : Colors.white70,
                                        fontSize: minuteController?.selectedItem == index ? 20 : 16,
                                        fontWeight: minuteController?.selectedItem == index ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // AM/PM picker
                        Expanded(
                          child: Container(
                            height: 130,
                            child: ListWheelScrollView.useDelegate(
                              controller: periodController,
                              itemExtent: 28, // Reduce item height
                              perspective: 0.005,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                final items = ["AM", "PM"];
                                final isPM = items[index] == "PM";
                                
                                if (_editingStartTime) {
                                  int newHour = selectedStartTime.hour;
                                  if (isPM && newHour < 12) {
                                    newHour += 12;
                                  } else if (!isPM && newHour >= 12) {
                                    newHour -= 12;
                                  }
                                  
                                  selectedStartTime = DateTime(
                                    selectedStartTime.year,
                                    selectedStartTime.month,
                                    selectedStartTime.day,
                                    newHour,
                                    selectedStartTime.minute,
                                  );
                                  _startTime = DateFormat('hh:mm a').format(selectedStartTime);
                                } else {
                                  int newHour = selectedEndTime.hour;
                                  if (isPM && newHour < 12) {
                                    newHour += 12;
                                  } else if (!isPM && newHour >= 12) {
                                    newHour -= 12;
                                  }
                                  
                                  selectedEndTime = DateTime(
                                    selectedEndTime.year,
                                    selectedEndTime.month,
                                    selectedEndTime.day,
                                    newHour,
                                    selectedEndTime.minute,
                                  );
                                  _endTime = DateFormat('hh:mm a').format(selectedEndTime);
                                }
                                
                                // Update displayed duration
                                durationMinutes = _calculateDurationInMinutes();
                                setState(() {});
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 2,
                                builder: (context, index) {
                                  final items = ["AM", "PM"];
                                  return Center(
                                    child: Text(
                                      items[index],
                                      style: TextStyle(
                                        color: periodController?.selectedItem == index ? _colorList[_selectedColor] : Colors.white70,
                                        fontSize: periodController?.selectedItem == index ? 20 : 16,
                                        fontWeight: periodController?.selectedItem == index ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Confirm button
                  GestureDetector(
                    onTap: () {
                      // Update parent page state
                      Navigator.pop(context);
                      
                      // Update parent component state
                      this.setState(() {
                        // Recalculate task duration
                        _selectedRemind = _calculateDurationInMinutes();
                      });
                      
                      // Complete asynchronous operation, return true indicating user confirmed the selection
                      completer.complete(true);
                    },
                    child: Container(
                      height: 50, // Reduce button height
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _colorList[_selectedColor],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          "Confirm",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 5), // Reduce bottom spacing
                  
                  // Task end time information - Only show if ends after midnight
                  if (_checkIfEndsAfterMidnight())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5), // Reduce vertical padding
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nightlight_round, color: Colors.blue[400], size: 18),
                          const SizedBox(width: 5),
                          Text(
                            "Ends after midnight",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "+1",
                              style: TextStyle(
                                color: Colors.blue[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Dialog closed, update UI
      setState(() {});
      
      // If dialog was closed improperly (e.g., clicked outside area), it's considered canceled
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      
      // 释放控制器
      hourController?.dispose();
      minuteController?.dispose();
      periodController?.dispose();
    });
    
    return completer.future;
  }

  // Add method to check if task ends after midnight
  bool _checkIfEndsAfterMidnight() {
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime startDateTime = format.parse(_startTime);
    final DateTime endDateTime = format.parse(_endTime);
    
    // Check if past midnight (end time less than start time, or equal but one is AM and the other is PM)
    if (endDateTime.hour < startDateTime.hour) {
      return true;
    } else if (endDateTime.hour == startDateTime.hour && 
               endDateTime.minute < startDateTime.minute &&
               (startDateTime.hour < 12 && endDateTime.hour < 12)) {
      return true;
    }
    
    // Check AM/PM difference
    bool startIsPM = _startTime.toLowerCase().contains('pm');
    bool endIsAM = _endTime.toLowerCase().contains('am');
    
    return startIsPM && endIsAM;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dialogBackgroundColor: Colors.black87,
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.black87,
          hourMinuteTextColor: Colors.white,
          dayPeriodTextColor: Colors.white,
          dialHandColor: _colorList[_selectedColor],
          dialBackgroundColor: Colors.grey[800],
          dialTextColor: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: darkGreyClr,
        appBar: AppBar(
          backgroundColor: darkGreyClr,
          elevation: 0,
          title: Text(
            widget.task == null ? 'New Task' : 'Edit Task',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Title Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.task_alt,
                        color: _colorList[_selectedColor],
                      ),
                      hintText: 'Did',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Selection
                _buildSectionTitle('When?'),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final now = DateTime.now();
                      final time = DateTime(now.year, now.month, now.day, 16, 15 + index * 15);
                      final timeString = DateFormat('hh:mm a').format(time);
                      
                      // Calculate end time based on selected duration
                      final endTime = time.add(Duration(minutes: _selectedRemind));
                      final endTimeString = DateFormat('hh:mm a').format(endTime);
                      
                      // Format time range display
                      String timeRange = '';
                      String startTimeOnly = timeString.split(' ')[0];
                      String endTimeOnly = endTimeString.split(' ')[0];
                      
                      // Check if start and end times have the same period (AM/PM)
                      if (timeString.split(' ')[1] == endTimeString.split(' ')[1]) {
                        timeRange = '$startTimeOnly–$endTimeOnly ${timeString.split(' ')[1]}';
                      } else {
                        timeRange = '$startTimeOnly ${timeString.split(' ')[1]}–$endTimeOnly ${endTimeString.split(' ')[1]}';
                      }
                      
                      // 在编辑任务模式下，检查是否匹配现有任务时间
                      bool isTaskTime = widget.task != null && _selectedTimeIndex == 0 && index == 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            // 保存之前的时间值，以便取消时恢复
                            String previousStartTime = _startTime;
                            String previousEndTime = _endTime;
                            
                            setState(() {
                              // 如果是编辑任务的初始状态，则取消掉初始状态标记
                              if (widget.task != null && _selectedTimeIndex == 0 && index == 0) {
                                // 直接打开时间选择器，不改变当前时间
                                _selectedTimeIndex = index;
                              } else {
                                _selectedTimeIndex = index;
                                
                                // 更新为新的时间
                                _startTime = timeString;
                                // Calculate end time
                                final endTime = time.add(Duration(minutes: _selectedRemind));
                                _endTime = DateFormat('hh:mm a').format(endTime);
                                _showTimeRange = true;
                              }
                              
                              // Show time picker dialog, and restore previous time on cancel
                              _showTimePickerDialog(isStartTime: true).then((confirmed) {
                                if (confirmed != true) {
                                  // If not confirmed, restore previous time
                                  setState(() {
                                    if (widget.task != null && index == 0 && _selectedTimeIndex == 0) {
                                      // 还原到任务原始时间
                                      _startTime = widget.task!.startTime!;
                                      _endTime = widget.task!.endTime!;
                                    } else {
                                      _startTime = previousStartTime;
                                      _endTime = previousEndTime;
                                    }
                                  });
                                } else {
                                  // If confirmed time selection, force refresh UI
                                  setState(() {
                                    // No additional operation needed, just trigger setState to refresh UI
                                  });
                                }
                              });
                            });
                          },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: (_selectedTimeIndex == index || isTaskTime) ? _colorList[_selectedColor] : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                (_selectedTimeIndex == index || isTaskTime) ? 
                                  // 显示当前实际的开始和结束时间，而不是预先计算的
                                  _getFormattedTimeRange() : 
                                  timeString,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: (_selectedTimeIndex == index || isTaskTime) ? Colors.white : Colors.grey[400],
                                  fontSize: 20,
                                  fontWeight: (_selectedTimeIndex == index || isTaskTime) ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Date display with icon
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showCalendar = !_showCalendar;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, color: _colorList[_selectedColor], size: 20),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Calendar view
                if (_showCalendar)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        // Month navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _currentMonth,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                                  onPressed: () {}, // Placeholder
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                                      _updateCurrentMonth();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                                      _updateCurrentMonth();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _showCalendar = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Weekday headers
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Text('SUN', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('MON', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('TUE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('WED', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('THU', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('FRI', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('SAT', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        
                        // Calendar grid
                        SizedBox(
                          height: 240,
                          child: _buildCalendarGrid(),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),

                // Duration Selection
                _buildSectionTitle('How long?'),
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // Custom duration slider with connected buttons
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Stack(
                              children: [
                                // Background for selected range
                                Positioned.fill(
                                  child: Row(
                                    children: List.generate(_durationOptions.length, (index) {
                                      final duration = _durationOptions[index];
                                      final isSelected = _selectedRemind >= duration;
                                      // Calculate flex based on width
                                      return Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                              ? (_selectedRemind == duration 
                                                  ? _colorList[_selectedColor] 
                                                  : _colorList[_selectedColor].withOpacity(0.5))
                                              : Colors.grey[800],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // Duration labels
                                Row(
                                  children: List.generate(_durationOptions.length, (index) {
                                    final duration = _durationOptions[index];
                                    final isSelected = _selectedRemind == duration;
                                    
                                    String label;
                                    if (duration == 1) {
                                      label = '1';
                                    } else if (duration < 60) {
                                      label = isSelected ? '${duration}min' : '${duration}';
                                    } else if (duration == 60) {
                                      label = isSelected ? '1h' : '1';
                                    } else {
                                      label = isSelected ? '1.5h' : '1.5';
                                    }
                                    
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRemind = duration;
                                            if (_selectedTimeIndex >= 0) {
                                              final now = DateTime.now();
                                              final time = DateTime(now.year, now.month, now.day, 16, 45 + _selectedTimeIndex * 15);
                                              final endTime = time.add(Duration(minutes: duration));
                                              _endTime = DateFormat('hh:mm a').format(endTime);
                                            }
                                          });
                                        },
                                        child: Center(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: isSelected || _selectedRemind > duration 
                                                  ? Colors.white 
                                                  : Colors.grey[400],
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Color Selection
                _buildSectionTitle('What color?'),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = index;
                            });
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _colorList[index],
                            child: _selectedColor == index
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Create Task Button
                GestureDetector(
                  onTap: _validateAndSave,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _colorList[_selectedColor],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        widget.task == null ? 'Create Task' : 'Update Task',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() {
    if (_titleController.text.isNotEmpty) {
      if (widget.task == null) {
        _addTasksToDb();
      } else {
        _updateTaskInDb();
      }
      Get.back();
    } else {
      Get.snackbar(
        'Required', 
        'Title field is required!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: Colors.red,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      );
    }
  }

  _addTasksToDb() async {
    try {
      await _taskController.addTask(
        task: Task(
          title: _titleController.text,
          note: _noteController.text,
          isCompleted: 0,
          date: DateFormat.yMd().format(_selectedDate),
          startTime: _startTime,
          endTime: _endTime,
          color: _selectedColor,
          remind: _selectedRemind,
          repeat: _selectedRepeat,
        ),
      );
    } catch (e) {
      print('error: $e');
    }
  }

  _updateTaskInDb() async {
    try {
      await _taskController.editTask(
        Task(
          id: widget.task!.id,
          title: _titleController.text,
          note: _noteController.text,
          isCompleted: widget.task!.isCompleted,
          date: DateFormat.yMd().format(_selectedDate),
          startTime: _startTime,
          endTime: _endTime,
          color: _selectedColor,
          remind: _selectedRemind,
          repeat: _selectedRepeat,
        ),
      );
    } catch (e) {
      print('error: $e');
    }
  }

  Widget _buildCalendarGrid() {
    // Get first day of the month
    final DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    
    // Calculate the first day to display (might be from the previous month)
    int firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday, 1 = Monday, etc.
    
    // Get the number of days in the current month
    final int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    
    // Calculate number of rows needed
    final int rowCount = ((firstWeekday + daysInMonth) / 7).ceil();
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: rowCount * 7,
      itemBuilder: (context, index) {
        // Calculate the day and whether it belongs to the current month
        final int day = index - firstWeekday + 1;
        
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink(); // Empty cell for days from previous/next month
        }
        
        // Create a DateTime for this specific day
        final DateTime date = DateTime(_selectedDate.year, _selectedDate.month, day);
        
        // Check if this is the selected day
        final bool isSelected = date.year == _selectedDate.year && 
                               date.month == _selectedDate.month && 
                               date.day == _selectedDate.day;
        
        // Check if this is today
        final DateTime now = DateTime.now();
        final bool isToday = date.year == now.year && 
                           date.month == now.month && 
                           date.day == now.day;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _colorList[_selectedColor] : Colors.transparent,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isToday ? _colorList[_selectedColor] : Colors.white),
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 添加一个格式化显示当前选择的时间范围的方法
  String _getFormattedTimeRange() {
    // 分解开始时间
    List<String> startParts = _startTime.split(' ');
    String startTimeOnly = startParts[0];
    String startPeriod = startParts[1]; // AM/PM
    
    // 分解结束时间
    List<String> endParts = _endTime.split(' ');
    String endTimeOnly = endParts[0];
    String endPeriod = endParts[1]; // AM/PM
    
    // 检查开始和结束时间是否有相同的时段（AM/PM）
    if (startPeriod == endPeriod) {
      // 如果相同，只显示一次时段
      return '$startTimeOnly–$endTimeOnly $endPeriod';
    } else {
      // 如果不同，分别显示
      return '$startTimeOnly $startPeriod–$endTimeOnly $endPeriod';
    }
  }
}
