import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/task_controller.dart';
import 'package:todo/ui/theme.dart';
import '../../models/task.dart';

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
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeIndex = index;
                              _startTime = timeString;
                              // Calculate end time
                              final endTime = time.add(Duration(minutes: _selectedRemind));
                              _endTime = DateFormat('hh:mm a').format(endTime);
                              _showTimeRange = true;
                            });
                          },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: _selectedTimeIndex == index ? _colorList[_selectedColor] : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                _selectedTimeIndex == index ? timeRange : timeString,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedTimeIndex == index ? Colors.white : Colors.grey[400],
                                  fontSize: 20,
                                  fontWeight: _selectedTimeIndex == index ? FontWeight.bold : FontWeight.normal,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
          TextButton(
            onPressed: () {
              // Handle "More..." action
            },
            child: Text(
              'More...',
              style: TextStyle(
                color: _colorList[_selectedColor],
              ),
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
}
