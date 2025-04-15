import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  
  // 添加重复次数变量
  int _repeatCount = 1;
  
  final List<Color> _colorList = [
    Colors.green, // Green (default)
    Colors.blue,
    Colors.teal,
    Colors.purple,
    const Color(0xFFFF9AA2), // Pink
    Colors.orange,
    Colors.yellow,
  ];

  final List<int> _durationOptions = [15, 30, 45, 60, 90]; // in minutes

  // Add these variables for calendar view
  bool _showCalendar = false;
  String _currentMonth = '';

  // Add a variable to keep track of the selected time slot
  int _selectedTimeIndex = -1;


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
      
      // 处理重复设置
      String repeatSetting = widget.task!.repeat!;
      if (repeatSetting.contains(':')) {
        // 如果是格式为"Daily:3"这样的字符串，解析出重复类型和次数
        List<String> parts = repeatSetting.split(':');
        _selectedRepeat = parts[0];
        _repeatCount = int.tryParse(parts[1]) ?? 1;
      } else {
        _selectedRepeat = repeatSetting;
        _repeatCount = 1;
      }
      
      _selectedColor = widget.task!.color!;
      
      // 编辑任务时，设置选中状态以便正确显示时间框
      _selectedTimeIndex = 0; // 默认选中第一个时间框
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _startTime = DateFormat('hh:mm a').format(DateTime.now()).toString();
      // Set end time 15 minutes after start time by default
      final endTime = DateTime.now().add(const Duration(minutes: 15));
      _endTime = DateFormat('hh:mm a').format(endTime);
      // Set default selected remind to 15 minutes
      _selectedRemind = 15;
      // 设置默认为不重复
      _selectedRepeat = 'None';
      _repeatCount = 1;
    }
    _updateCurrentMonth();
  }
  
  void _updateCurrentMonth() {
    _currentMonth = DateFormat('MMMM yyyy').format(_selectedDate);
  }


  // 添加方法用于计算任务持续时间（分钟）
  int _calculateDurationInMinutes() {
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime startDateTime = format.parse(_startTime);
    final DateTime endDateTime = format.parse(_endTime);
    
    // 计算分钟差，考虑跨越午夜的情况
    int minutes = endDateTime.difference(startDateTime).inMinutes;
    
    // 如果是负数，说明跨越了午夜，需要加上24小时的分钟数
    if (minutes < 0) {
      minutes += 24 * 60; // 加上一天的分钟数
    }
    
    return minutes;
  }
  
  // 添加方法将分钟转换为小时和分钟的格式化文本
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      
      if (remainingMinutes == 0) {
        return hours == 1 ? '1 hour' : '$hours hours';
      } else {
        final String hourText = hours == 1 ? '1 hour' : '$hours hours';
        return '$hourText $remainingMinutes minutes';
      }
    }
  }

  // Add this method to show time picker dialog
  Future<bool> _showTimePickerDialog({required bool isStartTime}) {
    // Create a Completer to handle asynchronous result
    final completer = Completer<bool>();
    
    // Use a variable to track which is currently being edited (start time or end time)
    bool editingStartTime = isStartTime;
    
    // 创建控制器供滚轮使用
    FixedExtentScrollController? hourController;
    FixedExtentScrollController? minuteController;
    FixedExtentScrollController? periodController;
    
    // 使用严格的格式化器，确保时间格式一致
    final DateFormat format = DateFormat('hh:mm a');
    
    // 获取当前时间
    final DateTime initialTime = format.parse(isStartTime ? _startTime : _endTime);
    
    // 打印当前时间以便调试
    print('初始${isStartTime ? "开始" : "结束"}时间: ${isStartTime ? _startTime : _endTime}');
    print('解析后的时间: ${format.format(initialTime)}');
    
    // 小时 (1-12)
    final int hour12 = initialTime.hour > 12 ? initialTime.hour - 12 : (initialTime.hour == 0 ? 12 : initialTime.hour);
    hourController = FixedExtentScrollController(initialItem: hour12 - 1);
    
    // 分钟 (00-59)
    minuteController = FixedExtentScrollController(initialItem: initialTime.minute);
    
    // 时段 (AM/PM)
    final isPM = initialTime.hour >= 12;
    periodController = FixedExtentScrollController(initialItem: isPM ? 1 : 0);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: darkGreyClr,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Add this to make the bottom sheet larger
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Parse the current selected time
            final DateFormat format = DateFormat('hh:mm a');
            
            // Calculate task duration
            int durationMinutes = _calculateDurationInMinutes();
            
            return Container(
              height: 500, // Increased from 470 to 500 to accommodate larger time picker
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
                      'This task takes ${_formatDuration(durationMinutes)}.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18, // Reduce font size
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
                            // 解析开始时间
                            final DateFormat format = DateFormat('hh:mm a');
                            final DateTime startDateTime = format.parse(_startTime);
                            
                            // 计算小时和分钟值
                            final int hour12 = startDateTime.hour > 12 ? startDateTime.hour - 12 : (startDateTime.hour == 0 ? 12 : startDateTime.hour);
                            final int minute = startDateTime.minute;
                            final isPM = startDateTime.hour >= 12;
                            
                            setState(() {
                              editingStartTime = true;
                            });
                            
                            // 使用延时确保控制器已经安全连接到视图
                            Future.delayed(const Duration(milliseconds: 50), () {
                              // 直接控制滚轮跳转到特定位置
                              hourController?.jumpToItem(hour12 - 1);
                              minuteController?.jumpToItem(minute);
                              periodController?.jumpToItem(isPM ? 1 : 0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8), // Reduce padding
                            decoration: BoxDecoration(
                              color: editingStartTime ? _colorList[_selectedColor] : Colors.grey[800],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Start',
                                  style: TextStyle(
                                    color: editingStartTime ? Colors.white : Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startTime,
                                  style: TextStyle(
                                    color: editingStartTime ? Colors.white : Colors.grey[400],
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
                            // 解析结束时间
                            final DateFormat format = DateFormat('hh:mm a');
                            final DateTime endDateTime = format.parse(_endTime);
                            
                            // 计算小时和分钟值
                            final int hour12 = endDateTime.hour > 12 ? endDateTime.hour - 12 : (endDateTime.hour == 0 ? 12 : endDateTime.hour);
                            final int minute = endDateTime.minute;
                            final isPM = endDateTime.hour >= 12;
                            
                            setState(() {
                              editingStartTime = false;
                            });
                            
                            // 使用延时确保控制器已经安全连接到视图
                            Future.delayed(const Duration(milliseconds: 50), () {
                              // 直接控制滚轮跳转到特定位置
                              hourController?.jumpToItem(hour12 - 1);
                              minuteController?.jumpToItem(minute);
                              periodController?.jumpToItem(isPM ? 1 : 0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8), // Reduce padding
                            decoration: BoxDecoration(
                              color: !editingStartTime ? _colorList[_selectedColor] : Colors.grey[800],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'End',
                                  style: TextStyle(
                                    color: !editingStartTime ? Colors.white : Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endTime,
                                  style: TextStyle(
                                    color: !editingStartTime ? Colors.white : Colors.grey[400],
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
                  
                  const SizedBox(height: 10),
                  
                  // Time picker - 改用CupertinoTimerPicker来确保惯性滚动
                  Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        // 小时选择器
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: hourController,
                            looping: true, // 支持循环滚动
                            useMagnifier: true,
                            magnification: 1.2,
                            squeeze: 1.0,
                            itemExtent: 40,
                            selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                              background: _colorList[_selectedColor].withOpacity(0.15),
                            ),
                            onSelectedItemChanged: (index) {
                              final newHour = index + 1; // 1-12
                              final DateFormat format = DateFormat('hh:mm a');
                              DateTime currentTime = format.parse(editingStartTime ? _startTime : _endTime);
                              
                              // 计算新的24小时制小时值
                              bool isPM = currentTime.hour >= 12;
                              int hour24;
                              if (newHour == 12) {
                                hour24 = isPM ? 12 : 0;
                              } else {
                                hour24 = isPM ? newHour + 12 : newHour;
                              }
                              
                              // 创建新的时间
                              DateTime newTime = DateTime(
                                currentTime.year,
                                currentTime.month,
                                currentTime.day,
                                hour24,
                                currentTime.minute,
                              );
                              
                              // 格式化并更新时间
                              String timeString = DateFormat('hh:mm a').format(newTime);
                              
                              setState(() {
                                if (editingStartTime) {
                                  _startTime = timeString;
                                } else {
                                  _endTime = timeString;
                                }
                                
                                // 更新持续时间
                                durationMinutes = _calculateDurationInMinutes();
                              });
                            },
                            children: List.generate(12, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1}'.padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        
                        // 分隔符
                        SizedBox(
                          width: 20,
                          child: Center(
                            child: Text(
                              ':',
                              style: TextStyle(
                                color: _colorList[_selectedColor],
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // 分钟选择器
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: minuteController,
                            looping: true, // 支持循环滚动
                            useMagnifier: true,
                            magnification: 1.2,
                            squeeze: 1.0,
                            itemExtent: 40,
                            selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                              background: _colorList[_selectedColor].withOpacity(0.15),
                            ),
                            onSelectedItemChanged: (index) {
                              final DateFormat format = DateFormat('hh:mm a');
                              DateTime currentTime = format.parse(editingStartTime ? _startTime : _endTime);
                              
                              // 创建新的时间
                              DateTime newTime = DateTime(
                                currentTime.year,
                                currentTime.month,
                                currentTime.day,
                                currentTime.hour,
                                index,
                              );
                              
                              // 格式化并更新时间
                              String timeString = DateFormat('hh:mm a').format(newTime);
                              
                              setState(() {
                                if (editingStartTime) {
                                  _startTime = timeString;
                                } else {
                                  _endTime = timeString;
                                }
                                
                                // 更新持续时间
                                durationMinutes = _calculateDurationInMinutes();
                              });
                            },
                            children: List.generate(60, (index) {
                              return Center(
                                child: Text(
                                  '$index'.padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        
                        // 分隔符
                        const SizedBox(width: 5),
                        
                        // AM/PM选择器
                        SizedBox(
                          width: 70,
                          child: CupertinoPicker(
                            scrollController: periodController,
                            useMagnifier: true,
                            magnification: 1.2,
                            squeeze: 1.0,
                            itemExtent: 40,
                            selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                              background: _colorList[_selectedColor].withOpacity(0.15),
                            ),
                            onSelectedItemChanged: (index) {
                              final bool newIsPM = index == 1;
                              final DateFormat format = DateFormat('hh:mm a');
                              DateTime currentTime = format.parse(editingStartTime ? _startTime : _endTime);
                              
                              // 当前小时值（12小时制）
                              int hour12 = currentTime.hour % 12;
                              if (hour12 == 0) hour12 = 12;
                              
                              // 根据AM/PM计算新的24小时制小时值
                              int newHour24;
                              if (hour12 == 12) {
                                newHour24 = newIsPM ? 12 : 0;
                              } else {
                                newHour24 = newIsPM ? hour12 + 12 : hour12;
                              }
                              
                              // 创建新的时间
                              DateTime newTime = DateTime(
                                currentTime.year,
                                currentTime.month,
                                currentTime.day,
                                newHour24,
                                currentTime.minute,
                              );
                              
                              // 格式化并更新时间
                              String timeString = DateFormat('hh:mm a').format(newTime);
                              
                              setState(() {
                                if (editingStartTime) {
                                  _startTime = timeString;
                                } else {
                                  _endTime = timeString;
                                }
                                
                                // 更新持续时间
                                durationMinutes = _calculateDurationInMinutes();
                              });
                            },
                            children: const [
                              Center(
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'PM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
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
                      child: const Center(
                        child: Text(
                          'Confirm',
                          style: TextStyle(
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
                          const Text(
                            'Ends after midnight',
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
                              '+1',
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

  // 更新判断任务是否跨越午夜的方法
  bool _checkIfEndsAfterMidnight() {
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime startDateTime = format.parse(_startTime);
    final DateTime endDateTime = format.parse(_endTime);
    
    // 计算分钟差，如果是负数则跨越了午夜
    int minutes = endDateTime.difference(startDateTime).inMinutes;
    if (minutes < 0) {
      return true;
    }
    
    // 保留原有逻辑，检查AM/PM差异
    bool startIsPM = _startTime.toLowerCase().contains('pm');
    bool endIsAM = _endTime.toLowerCase().contains('am');
    
    return startIsPM && endIsAM;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.black87,
          hourMinuteTextColor: Colors.white,
          dayPeriodTextColor: Colors.white,
          dialHandColor: _colorList[_selectedColor],
          dialBackgroundColor: Colors.grey[800],
          dialTextColor: Colors.white,
        ), dialogTheme: const DialogThemeData(backgroundColor: Colors.black87),
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
                    cursorColor: _colorList[_selectedColor],
                    cursorWidth: 3.0, // 使用更粗的光标
                    cursorRadius: const Radius.circular(2.0),
                    showCursor: true, // 确保光标始终可见
                    autofocus: true, // 在页面加载时自动获得焦点
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.task_alt,
                        color: _colorList[_selectedColor],
                      ),
                      hintText: '', // 移除"Did"占位文本
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Selection
                _buildSectionTitle('When?'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Date selection row
                      GestureDetector(
                          onTap: () {
                            setState(() {
                            _showCalendar = !_showCalendar;
                            });
                          },
                          child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                            decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                    child: Row(
                      children: [
                              Icon(
                                Icons.calendar_today,
                                color: _colorList[_selectedColor],
                                size: 20,
                              ),
                              const SizedBox(width: 15),
                        Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                                  color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                              const Spacer(),
                              Icon(
                                _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.white70,
                                size: 20,
                              ),
                      ],
                    ),
                  ),
                ),
                
                      // Calendar View
                if (_showCalendar)
                  Container(
                          margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                    ),
                          padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // Month navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _currentMonth,
                                  style: const TextStyle(
                                    color: Colors.white,
                                      fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                        icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                                      _updateCurrentMonth();
                                    });
                                  },
                                ),
                                IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                                      _updateCurrentMonth();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Calendar grid
                        SizedBox(
                                height: 230,
                          child: _buildCalendarGrid(),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),

                      // Time selection fields
                      Row(
                    children: [
                          // Start Time Field
                      Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                // Show time picker dialog with Start time
                                await _showTimePickerDialog(isStartTime: true);
                                // Update UI
                                setState(() {});
                              },
                          child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: _colorList[_selectedColor], size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          _startTime,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 15),
                          
                          // End Time Field
                          Expanded(
                                      child: GestureDetector(
                              onTap: () async {
                                // Show time picker dialog with End time
                                await _showTimePickerDialog(isStartTime: false);
                                // Update UI
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                            style: TextStyle(
                                        color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: _colorList[_selectedColor], size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          _endTime,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Duration info
                      Container(
                        margin: const EdgeInsets.only(top: 15),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: _colorList[_selectedColor].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _colorList[_selectedColor].withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timelapse,
                              color: _colorList[_selectedColor],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Duration: ${_formatDuration(_calculateDurationInMinutes())}',
                              style: TextStyle(
                                color: _colorList[_selectedColor],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Repeat Option Section
                _buildSectionTitle('How often?', showDate: true),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // 选择重复模式的按钮
                      Container(
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(child: _buildRepeatOptionButton('Once', 'None', isFirst: true)),
                            Expanded(child: _buildRepeatOptionButton('Daily', 'Daily')),
                            Expanded(child: _buildRepeatOptionButton('Weekly', 'Weekly')),
                            Expanded(child: _buildRepeatOptionButton('Monthly', 'Monthly', isLast: true)),
                          ],
                        ),
                      ),
                      
                      // 如果选择不是"Once"，显示重复次数调整UI
                      if (_selectedRepeat != 'None')
                        Column(
                          children: [
                            const SizedBox(height: 10), // 添加间隙
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getRepeatText(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      children: [
                                        // 减少按钮
                                        IconButton(
                                          icon: const Icon(Icons.remove, color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              if (_repeatCount > 1) {
                                                _repeatCount--;
                                              }
                                            });
                                          },
                                        ),
                                        // 显示当前次数
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _colorList[_selectedColor],
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            '$_repeatCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // 增加按钮
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              _repeatCount++;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

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

  Widget _buildSectionTitle(String title, {bool showDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
          if (showDate)
            Text(
              'Starting on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
              style: TextStyle(
                color: Colors.pink[300],
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
          repeat: _selectedRepeat == 'None' ? 'None' : "$_selectedRepeat:$_repeatCount",
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
          repeat: _selectedRepeat == 'None' ? 'None' : "$_selectedRepeat:$_repeatCount",
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
    // 使用统一的DateFormat实例处理时间
    final DateFormat format = DateFormat('hh:mm a');
    
    try {
      // 解析时间字符串为DateTime对象
      final DateTime startDateTime = format.parse(_startTime);
      final DateTime endDateTime = format.parse(_endTime);
      
      // 再次格式化以确保格式一致
      final String formattedStartTime = format.format(startDateTime);
      final String formattedEndTime = format.format(endDateTime);
      
      // 分解开始时间
      List<String> startParts = formattedStartTime.split(' ');
      String startTimeOnly = startParts[0];
      String startPeriod = startParts[1]; // AM/PM
      
      // 分解结束时间
      List<String> endParts = formattedEndTime.split(' ');
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
    } catch (e) {
      print('Error formatting time range: $e');
      return '$_startTime–$_endTime';
    }
  }

  Widget _buildRepeatOptionButton(String label, String value, {bool isFirst = false, bool isLast = false}) {
    bool isSelected = _selectedRepeat == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRepeat = value;
          // 如果从其他选项切换回"Once"，重置重复次数
          if (value == 'None') {
            _repeatCount = 1;
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? _colorList[_selectedColor] : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 10 : 0),
            bottomLeft: Radius.circular(isFirst ? 10 : 0),
            topRight: Radius.circular(isLast ? 10 : 0),
            bottomRight: Radius.circular(isLast ? 10 : 0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // 获取重复文本的方法，根据选择和数量返回正确的单复数形式
  String _getRepeatText() {
    String unit = '';
    switch (_selectedRepeat) {
      case 'Daily':
        unit = _repeatCount == 1 ? 'day' : 'days';
        break;
      case 'Weekly':
        unit = _repeatCount == 1 ? 'week' : 'weeks';
        break;
      case 'Monthly':
        unit = _repeatCount == 1 ? 'month' : 'months';
        break;
      default:
        return '';
    }
    // 如果是1，就不显示数字
    return _repeatCount == 1 ? 'Every $unit' : 'Every $_repeatCount $unit';
  }
}
