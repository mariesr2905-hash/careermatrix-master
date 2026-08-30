import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';

class ImportExcelModal extends StatefulWidget {
  const ImportExcelModal({super.key});

  @override
  State<ImportExcelModal> createState() => _ImportExcelModalState();
}

class _ImportExcelModalState extends State<ImportExcelModal> {
  int _currentStep = 0;
  String _selectedRole = 'STUDENT';
  
  bool _isLoading = false;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  
  Map<String, dynamic>? _validationSummary;
  List<Map<String, dynamic>> _previewRecords = [];
  String? _errorMessage;

  final List<String> _roles = ['STUDENT', 'ALUMNI', 'MENTOR', 'COMPANY', 'ADMIN'];

  Future<void> _downloadTemplate() async {
    setState(() => _isLoading = true);
    try {
      await BackendRepository.instance.downloadExcelTemplate(_selectedRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template for $_selectedRole downloaded successfully.')),
        );
        setState(() => _currentStep = 2); // Auto advance to upload step
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        List<int> bytes;
        if (file.bytes != null) {
          bytes = file.bytes!;
        } else if (file.path != null) {
          final fileObject = File(file.path!);
          bytes = await fileObject.readAsBytes();
        } else {
          throw Exception('Could not read file bytes.');
        }

        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = bytes;
          _errorMessage = null;
        });

        // Run validation immediately after picking file
        await _validateFile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select file: $e';
      });
    }
  }

  Future<void> _validateFile() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await BackendRepository.instance.validateExcelImport(
        userType: _selectedRole,
        bytes: _selectedFileBytes!,
        filename: _selectedFileName!,
      );

      setState(() {
        _validationSummary = response['summary'] as Map<String, dynamic>?;
        _previewRecords = (response['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _currentStep = 3; // Advance to preview step
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importRecords() async {
    final validRecords = _previewRecords.where((r) => r['validation'] == 'valid').toList();
    if (validRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid records to import.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await BackendRepository.instance.confirmExcelImport(
        userType: _selectedRole,
        records: validRecords,
      );
      setState(() {
        _currentStep = 4; // Advance to success step
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Import failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getRowColor(String validation) {
    switch (validation) {
      case 'valid':
        return Colors.green.shade50;
      case 'duplicate':
        return Colors.amber.shade50;
      case 'invalid':
        return Colors.red.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getRowTextColor(String validation) {
    switch (validation) {
      case 'valid':
        return Colors.green.shade800;
      case 'duplicate':
        return Colors.amber.shade900;
      case 'invalid':
        return Colors.red.shade800;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _currentStep == 3 ? 900 : 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulk Excel Import — Step ${_currentStep + 1} of 5',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context, _currentStep == 4),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else ...[
              _buildStepContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildSelectRoleStep();
      case 1:
        return _buildDownloadTemplateStep();
      case 2:
        return _buildUploadFileStep();
      case 3:
        return _buildPreviewStep();
      case 4:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSelectRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the user category you wish to import:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          decoration: const InputDecoration(labelText: 'User Category'),
          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedRole = val);
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadTemplateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please download the template Excel file for $_selectedRole. Ensure your file columns match the template exactly.',
          style: const TextStyle(height: 1.4),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Excel Template'),
            onPressed: _downloadTemplate,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Skip & Upload File'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadFileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload your completed Excel (.xlsx) file:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primarySoft.withOpacity(0.2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    _selectedFileName ?? 'Choose Excel File',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  if (_selectedFileName == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Only .xlsx files are supported', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: _selectedFileBytes != null ? _validateFile : null,
              child: const Text('Validate & Preview'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    final valid = _validationSummary?['valid'] ?? 0;
    final invalid = _validationSummary?['invalid'] ?? 0;
    final duplicate = _validationSummary?['duplicate'] ?? 0;
    final total = _validationSummary?['total'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Valid: $valid', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Text('Invalid: $invalid', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            Text('Duplicate: $duplicate', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Previewing Imported Records:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.surfaceMuted),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role/Dept')),
                  DataColumn(label: Text('Validation')),
                  DataColumn(label: Text('Status Details')),
                ],
                rows: _previewRecords.map((r) {
                  final val = r['validation']?.toString() ?? 'valid';
                  return DataRow(
                    color: MaterialStateProperty.all(_getRowColor(val)),
                    cells: [
                      DataCell(Text(r['name']?.toString() ?? '—', style: TextStyle(color: _getRowTextColor(val)))),
                      DataCell(Text(r['email']?.toString() ?? '—', style: TextStyle(color: _getRowTextColor(val)))),
                      DataCell(Text(r['department']?.toString() ?? '—', style: TextStyle(color: _getRowTextColor(val)))),
                      DataCell(Text(val.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: _getRowTextColor(val)))),
                      DataCell(Text(r['statusText']?.toString() ?? '', style: TextStyle(fontSize: 12, color: _getRowTextColor(val)))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Cancel / Re-upload'),
            ),
            ElevatedButton(
              onPressed: valid > 0 ? _importRecords : null,
              child: Text('Import Valid Records ($valid)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    final valid = _validationSummary?['valid'] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            '$valid users imported successfully.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '$valid accounts are pending administrator approval.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
