import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:stridelog/controllers/auth_provider.dart';
import 'package:stridelog/controllers/activity_provider.dart';
import 'package:stridelog/models/activity.dart';
import 'package:stridelog/services/validation_service.dart';
import 'package:stridelog/services/database_service.dart';
import 'package:stridelog/services/weather_service.dart';
import 'package:stridelog/logic/weather_logic.dart';

class AddActivityScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddActivityScreen({super.key, this.onSaved});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  ActivityType _selectedType = ActivityType.running;
  String? _selectedCustomTypeName;
  List<String> _customTypes = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  String? _imagePath;
  String? _weatherInfo;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadCustomTypes();
    _fetchWeather();
  }

  Future<void> _loadCustomTypes() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final types = await DatabaseService.getCustomActivityTypes(user.id);
    setState(() => _customTypes = types);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    }
  }

  Future<void> _fetchWeather() async {
    setState(() => _isLoadingWeather = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {

        Position position = await Geolocator.getCurrentPosition();
        final weather = await WeatherService().getCurrentWeather(
            position.latitude,
            position.longitude
        );

        setState(() => _weatherInfo = weather);
      }
    } catch (e) {
      debugPrint('Erro clima: $e');
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFF6B35),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    if (_selectedType == ActivityType.custom &&
        (_selectedCustomTypeName == null ||
            _selectedCustomTypeName!.trim().isEmpty)) {
      _showSnack('Defina o nome do tipo personalizado', error: true);
      return;
    }

    setState(() => _isLoading = true);

    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.id,
      type: _selectedType,
      customTypeName: _selectedType == ActivityType.custom
          ? _selectedCustomTypeName
          : null,
      durationMinutes: int.parse(_durationController.text),
      distanceKm: _distanceController.text.isNotEmpty
          ? double.parse(_distanceController.text)
          : null,
      calories: _caloriesController.text.isNotEmpty
          ? int.parse(_caloriesController.text)
          : null,
      date: _selectedDate,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      imagePath: _imagePath,
      weatherInfo: _weatherInfo,
    );

    final success = await context.read<ActivityProvider>().addActivity(activity);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _clearForm();
      _showSnack('Atividade salva com sucesso!', success: true);
      widget.onSaved?.call();
    } else if (mounted) {
      _showSnack('Erro ao salvar atividade', error: true);
    }
  }

  void _showSnack(String message, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF4CAF50)
            : error
            ? Theme.of(context).colorScheme.error
            : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearForm() {
    _durationController.clear();
    _distanceController.clear();
    _caloriesController.clear();
    _notesController.clear();
    setState(() {
      _selectedType = ActivityType.running;
      _selectedCustomTypeName = null;
      _selectedDate = DateTime.now();
      _imagePath = null;
      _weatherInfo = null;
    });
    _fetchWeather();
  }

  Future<void> _promptAddCustomType() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final controller = TextEditingController();
    final added = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Novo tipo de atividade'),
        content: TextField(
          controller: controller,
          decoration:
          const InputDecoration(labelText: 'Nome do tipo (ex.: Pilates)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Adicionar')),
        ],
      ),
    );

    if (added != null && added.isNotEmpty) {
      await DatabaseService.addCustomActivityType(user.id, added);
      await _loadCustomTypes();
      setState(() {
        _selectedType = ActivityType.custom;
        _selectedCustomTypeName = added;
      });
      _showSnack('Tipo "$added" adicionado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFE91E63)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child:
          const Icon(Icons.add_circle, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Nova Atividade',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registre sua atividade física',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    ),
  );

  Widget _buildForm() {
    // Avalia o clima para mostrar o status
    final weatherEvaluation = WeatherLogic.evaluate(_weatherInfo);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Tipo de atividade'),
          const SizedBox(height: 16),
          _buildActivityTypeSelector(),
          if (_selectedType == ActivityType.custom &&
              _selectedCustomTypeName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tipo selecionado: $_selectedCustomTypeName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _promptAddCustomType,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar novo tipo'),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Detalhes da atividade'),
          const SizedBox(height: 16),

          // --- WIDGET DO CLIMA COM AVALIAÇÃO ---
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: (weatherEvaluation['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (weatherEvaluation['color'] as Color).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(weatherEvaluation['icon'] as IconData, color: weatherEvaluation['color'] as Color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _weatherInfo ?? (_isLoadingWeather ? 'Buscando clima...' : 'Clima não disponível'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (!_isLoadingWeather && _weatherInfo == null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchWeather,
                      )
                  ],
                ),
                if (_weatherInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 36),
                    child: Text(
                      weatherEvaluation['status'] as String,
                      style: TextStyle(
                        color: weatherEvaluation['color'] as Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- WIDGET DA FOTO ---
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                image: _imagePath != null
                    ? DecorationImage(
                  image: FileImage(File(_imagePath!)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _imagePath == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text('Toque para adicionar foto', style: TextStyle(color: Colors.grey[600])),
                ],
              )
                  : Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black),
                        onPressed: _pickImage,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _durationController,
                  label: 'Duração (min)',
                  icon: Icons.timer,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      ValidationService.validatePositiveNumber(v, 'Duração'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _distanceController,
                  label: 'Distância (km)',
                  icon: Icons.straighten,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      ValidationService.validatePositiveDouble(v, 'Distância'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _caloriesController,
                  label: 'Calorias (kcal)',
                  icon: Icons.local_fire_department,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      ValidationService.validatePositiveNumber(v, 'Calorias'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildDateSelector()),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _notesController,
            label: 'Notas (opcional)',
            icon: Icons.note,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: Theme.of(context)
        .textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w600),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      );

  Widget _buildDateSelector() => GestureDetector(
    onTap: _selectDate,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data',
                    style:
                    TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildActivityTypeSelector() {
    final builtInTypes =
    ActivityType.values.where((t) => t != ActivityType.custom).toList();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: builtInTypes.length,
            itemBuilder: (context, i) {
              final type = builtInTypes[i];
              final selected = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedType = type;
                  _selectedCustomTypeName = null;
                }),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIcon(type),
                        color: selected
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_customTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text('Tipos personalizados',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customTypes.map((name) {
                final selected = _selectedType == ActivityType.custom &&
                    _selectedCustomTypeName == name;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = ActivityType.custom;
                    _selectedCustomTypeName = name;
                  }),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected
                          ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category,
                            color: selected
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            size: 22),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() => Container(
    height: 56,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFE91E63)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: _isLoading ? null : _saveActivity,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : const Text(
        'Salvar Atividade',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.gym:
        return Icons.fitness_center;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.yoga:
        return Icons.self_improvement;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.custom:
        return Icons.category;
    }
  }
}