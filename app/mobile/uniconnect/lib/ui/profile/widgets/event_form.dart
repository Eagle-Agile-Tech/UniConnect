import 'package:flutter/material.dart';
import 'package:flutter_nominatim/flutter_nominatim.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:intl/intl.dart';

class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _eventDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _pickEventDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _eventDay = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  final Nominatim nominatim = Nominatim.instance;
  List<Place> _locationSuggestions = [];
  bool _isSearching = false;

  // 2. Add this helper method for the search logic
  void _onLocationChanged(String query) async {
    if (query.length < 3) {
      setState(() => _locationSuggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await nominatim.search(query);
      setState(() {
        _locationSuggestions = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint("Nominatim Error: $e");
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (_formKey.currentState!.validate() &&
        _eventDay != null &&
        _startTime != null &&
        _endTime != null) {
      final starts = _combine(_eventDay!, _startTime!);
      final ends = _combine(_eventDay!, _endTime!);

      if (ends.isBefore(starts)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time must be after start time")),
        );
        return;
      }

      final event = {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "starts": starts.toIso8601String(),
        "ends": ends.toIso8601String(),
        "eventDay": _eventDay!.toIso8601String(),
        "authorId": _authorIdController.text,
      };

      debugPrint(event.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event Created Successfully!")),
      );
    }
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: _pickEventDay,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Event Day",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _eventDay == null
                ? 'Pick event day'
                : DateFormat.yMMMd().format(_eventDay!),
            style: TextStyle(
              color: _eventDay == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            time == null ? 'Pick $label' : time.format(context),
            style: TextStyle(color: time == null ? Colors.grey : Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Event"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Event Details",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  _buildInput(label: "Title", controller: _titleController),

                  _buildInput(
                    label: "Description",
                    controller: _descriptionController,
                    maxLines: 3,
                  ),

                  TextFormField(
                    controller: _locationController,
                    onChanged: _onLocationChanged,
                    decoration: InputDecoration(
                      labelText: "Event Location",
                      hintText: "Search places...",
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                      ),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  if (_locationSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final place = _locationSuggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.place_outlined, size: 20),
                            title: Text(
                              place.displayName,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              setState(() {
                                _locationController.text = place.displayName;
                                _locationSuggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),

                  _buildDateField(),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          "Start Time",
                          _startTime,
                          () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTimeField(
                          "End Time",
                          _endTime,
                          () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),

                  _buildInput(label: "Author", controller: _authorIdController),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Create Event",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
