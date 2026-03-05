import 'package:flutter/material.dart';

import 'package:frontend/api/student_api.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int activeStudents = 0;
  int blockedStudents = 0;
  int totalStudents = 0;

  int selectedPage = 0;

  String searchText = "";

  List<dynamic> students = [];
  bool loadingStudents = false;

  String? filterDept;
  String? filterSem;
  String? filterBatch;

  final departments = ["CSE", "EC", "EEE", "ME"];
  final semesters = List.generate(8, (i) => "${i + 1}");
  final batches = ["2023-2027", "2024-2028", "2025-2029", "2026-2030"];

  @override
  void initState() {
    super.initState();
    loadStudentCount();
  }

  Future<void> loadStudentCount() async {
    try {
      final count = await StudentApi.getStudentCount();
      final statusCounts = await StudentApi.getStudentStatusCounts();

      setState(() {
        totalStudents = count;
        activeStudents = statusCounts['active']!;
        blockedStudents = statusCounts['blocked']!;
      });
    } catch (e) {
      print("Error loading students: $e");
    }
  }

  Future<void> loadStudents() async {
    setState(() => loadingStudents = true);

    try {
      final data = await StudentApi.getAllStudents();
      setState(() => students = data);
    } catch (e) {
      print("Error loading students: $e");
    }

    setState(() => loadingStudents = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ✅ Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF6200EE),
              border: Border(right: BorderSide(color: Colors.black, width: 4)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "SemSeat Admin",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.white38, thickness: 1),

                _MenuItem(
                  icon: Icons.home,
                  text: "Home",
                  selected: selectedPage == 0,
                  onTap: () {
                    setState(() => selectedPage = 0);
                    loadStudents();
                  },
                ),

                _MenuItem(
                  icon: Icons.people,
                  text: "Students",
                  selected: selectedPage == 1,
                  onTap: () {
                    setState(() {
                      selectedPage = 1;
                      students = []; // reset list
                      loadingStudents = true;
                    });

                    loadStudents();
                  },
                ),

                const Spacer(),

                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("v1.0", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),

          // ✅ Main Area
          Expanded(
            child: selectedPage == 0 ? _buildDashboard() : _buildStudentsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => _AddStudentDialog(
                      onStudentAdded: () {
                        loadStudents();
                        loadStudentCount();
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Student"),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.6,
              ),
              itemCount: 4,
              itemBuilder: (_, i) {
                final cards = [
                  ("Total Students", totalStudents.toString(), Icons.people),
                  (
                    "Active Students",
                    activeStudents.toString(),
                    Icons.check_circle,
                  ),
                  ("Blocked Students", blockedStudents.toString(), Icons.block),
                  ("Upcoming Exams", "3", Icons.event),
                ];

                return _DashboardCard(
                  title: cards[i].$1,
                  value: cards[i].$2,
                  icon: cards[i].$3,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsPage() {
    if (loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!loadingStudents && students.isEmpty) {
      return const Center(child: Text("No students found"));
    }

    // 🔹 Apply Search + Filters
    final filteredStudents = students.where((s) {
      final name = s['name'].toString().toLowerCase();
      final reg = s['registrationNumber'].toString().toLowerCase();

      if (!name.contains(searchText) && !reg.contains(searchText)) return false;

      if (filterDept != null && s['department'] != filterDept) return false;
      if (filterSem != null && s['semester'].toString() != filterSem)
        return false;
      if (filterBatch != null && s['batch'] != filterBatch) return false;

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ HEADER
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: const Text(
            "Students",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),

        // ✅ SEARCH BOX
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: 350,
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search name / registration number",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchText = v.toLowerCase()),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ✅ FILTER DROPDOWNS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _filterDropdown(
                "Department",
                departments,
                filterDept,
                (v) => setState(() => filterDept = v),
              ),
              const SizedBox(width: 20),
              _filterDropdown(
                "Semester",
                semesters,
                filterSem,
                (v) => setState(() => filterSem = v),
              ),
              const SizedBox(width: 20),
              _filterDropdown(
                "Batch",
                batches,
                filterBatch,
                (v) => setState(() => filterBatch = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ✅ STUDENT TABLE
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing:
                          constraints.maxWidth / 15, // ⭐ stretch columns
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFEDEDED),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            "Name",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Reg No",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Dept",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Sem",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Batch",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Actions",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                      rows: List.generate(filteredStudents.length, (i) {
                        final s = filteredStudents[i];

                        return DataRow(
                          color: MaterialStateProperty.all(
                            i % 2 == 0 ? Colors.white : const Color(0xFFF3F3F3),
                          ),
                          cells: [
                            DataCell(Text(s['name'] ?? "")),
                            DataCell(Text(s['registrationNumber'] ?? "")),
                            DataCell(Text(s['department'] ?? "")),
                            DataCell(Text(s['semester'].toString())),
                            DataCell(Text(s['batch'] ?? "")),
                            DataCell(Text(s['status'] ?? "")),

                            // ✅ Actions
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => _EditStudentDialog(
                                          student: s,
                                          onUpdated: () {
                                            loadStudents();
                                            loadStudentCount();
                                          },
                                        ),
                                      );
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Delete Student?"),
                                          content: Text(
                                            "Delete ${s['name']} permanently?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final success =
                                            await StudentApi.deleteStudent(
                                              s['id'],
                                            );
                                        if (success) {
                                          loadStudents();
                                          loadStudentCount();
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown(
    String label,
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text("All")),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;

  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: selected ? Colors.black : Colors.transparent,
            width: 5,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.black : Colors.white),
        title: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  final VoidCallback onStudentAdded;

  const _AddStudentDialog({required this.onStudentAdded});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final departments = ["CSE", "EC", "EEE", "ME"];
  final semesters = List.generate(8, (i) => "${i + 1}");
  final batches = ["2023-2027", "2024-2028", "2025-2029", "2026-2030"];

  String? selectedDepartment;
  String? selectedSemester;
  String? selectedBatch;

  final nameCtrl = TextEditingController();
  final regCtrl = TextEditingController();
  final deptCtrl = TextEditingController();
  final semCtrl = TextEditingController();
  final batchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Colors.black, width: 3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Add Student",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                    onChanged: (value) {
                      final formatted = toTitleCase(value);

                      if (formatted != value) {
                        nameCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
                _field("Registration Number", regCtrl),

                _dropdown(
                  label: "Department",
                  items: departments,
                  value: selectedDepartment,
                  onChanged: (v) => setState(() => selectedDepartment = v),
                ),

                _dropdown(
                  label: "Semester",
                  items: semesters,
                  value: selectedSemester,
                  onChanged: (v) => setState(() => selectedSemester = v),
                ),

                _dropdown(
                  label: "Batch",
                  items: batches,
                  value: selectedBatch,
                  onChanged: (v) => setState(() => selectedBatch = v),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        final success = await StudentApi.addStudent(
                          name: toTitleCase(nameCtrl.text),
                          regNo: regCtrl.text,
                          department: selectedDepartment ?? "",
                          semester: selectedSemester ?? "",
                          batch: selectedBatch ?? "",
                        );

                        if (!mounted) return;

                        navigator.pop();
                        if (success) {
                          widget.onStudentAdded(); // 👈 HERE
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? "Student added"
                                  : "Failed to add student",
                            ),
                          ),
                        );
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String toTitleCase(String text) {
    final words = text
        .trimLeft()
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? ''
              : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        );

    return words.join(' ');
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.zero,
          ),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _EditStudentDialog extends StatefulWidget {
  final Map student;
  final VoidCallback onUpdated;

  const _EditStudentDialog({required this.student, required this.onUpdated});

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController regCtrl;

  String? selectedDepartment;
  String? selectedSemester;
  String? selectedBatch;
  String? selectedStatus;

  final departments = ["CSE", "EC", "EEE", "ME"];
  final semesters = List.generate(8, (i) => "${i + 1}");
  final batches = ["2023-2027", "2024-2028", "2025-2029", "2026-2030"];
  final statuses = ["active", "blocked"];

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.student['name']);
    regCtrl = TextEditingController(text: widget.student['registrationNumber']);

    selectedDepartment = widget.student['department'];
    selectedSemester = widget.student['semester'].toString();
    selectedBatch = widget.student['batch'];
    selectedStatus = widget.student['status'];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Colors.black, width: 3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Edit Student",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: regCtrl,
                decoration: const InputDecoration(
                  labelText: "Registration Number",
                ),
              ),

              const SizedBox(height: 10),
              _dropdown(
                label: "Department",
                items: departments,
                value: selectedDepartment,
                onChanged: (v) => setState(() => selectedDepartment = v),
              ),

              _dropdown(
                label: "Semester",
                items: semesters,
                value: selectedSemester,
                onChanged: (v) => setState(() => selectedSemester = v),
              ),

              _dropdown(
                label: "Batch",
                items: batches,
                value: selectedBatch,
                onChanged: (v) => setState(() => selectedBatch = v),
              ),

              _dropdown(
                label: "Status",
                items: statuses,
                value: selectedStatus,
                onChanged: (v) => setState(() => selectedStatus = v),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await StudentApi.updateStudent(
                        id: widget.student['id'],
                        name: nameCtrl.text,
                        registrationNumber: regCtrl.text,
                        department: selectedDepartment ?? "",
                        semester: selectedSemester ?? "",
                        batch: selectedBatch ?? "",
                        status: selectedStatus ?? "active",
                      );

                      if (!mounted) return;

                      Navigator.pop(context);

                      if (success) {
                        widget.onUpdated(); // refresh list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Student updated")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to update student"),
                          ),
                        );
                      }
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.zero,
          ),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
