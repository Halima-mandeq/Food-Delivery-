import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:http/http.dart' as http;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, this.product});

  final ProductModel? product;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const List<String> _fallbackProjectImages = <String>[
    'images/login_hero.png',
    'images/onboarding_hero.png',
    'images/unnamed.png',
    'images/unnamed (1).png',
    'images/unnamed (2).png',
    'images/unnamed (3).png',
    'images/unnamed (4).png',
    'images/unnamed (5).png',
    'images/unnamed (6).png',
    'images/unnamed (7).png',
    'images/unnamed (8).png',
    'images/unnamed (9).png',
    'images/unnamed (10).png',
    'images/unnamed (11).png',
    'images/unnamed (12).png',
    'images/unnamed (13).png',
    'images/unnamed (14).png',
    'images/unnamed (15).png',
    'images/unnamed (16).png',
    'images/unnamed (17).png',
    'images/unnamed (18).png',
    'images/unnamed (19).png',
    'images/unnamed (20).png',
    'images/unnamed (21).png',
    'images/unnamed (22).png',
    'images/unnamed (23).png',
    'images/unnamed (24).png',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedImagePath;
  List<String> _categories = [];
  List<String> _projectImages = [];
  bool _isLoading = false;
  bool _isFetchingCategories = true;
  bool _isLoadingProjectImages = true;
  bool _isAvailable = true;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _setInitialValues();
    _fetchCategories();
    _loadProjectImages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _setInitialValues() {
    final product = widget.product;
    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _descController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(2);
    _selectedCategory = product.category;
    _isAvailable = product.isAvailable;

    if (product.imageUrl.isNotEmpty &&
        !product.imageUrl.startsWith('uploads/')) {
      _selectedImagePath = product.imageUrl;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/get_categories.php'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final categories = data.cast<String>();
        if (_selectedCategory != null &&
            _selectedCategory!.isNotEmpty &&
            !categories.contains(_selectedCategory)) {
          categories.add(_selectedCategory!);
        }
        setState(() {
          _categories = categories;
          _isFetchingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => _isFetchingCategories = false);
    }
  }

  Future<void> _loadProjectImages() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final images =
          manifest
              .listAssets()
              .where(
                (path) => path.startsWith('images/') && _isProjectImage(path),
              )
              .toSet()
              .toList()
            ..sort();
      final resolvedImages = images.isEmpty
          ? List<String>.from(_fallbackProjectImages)
          : images;

      if (!mounted) {
        return;
      }

      setState(() {
        _projectImages = resolvedImages;
        _selectedImagePath ??= _defaultProjectImage(resolvedImages);
        _isLoadingProjectImages = false;
      });
    } catch (e) {
      debugPrint('Error loading project images: $e');
      if (!mounted) {
        return;
      }

      setState(() {
        _projectImages = List<String>.from(_fallbackProjectImages);
        _selectedImagePath ??= _defaultProjectImage(_projectImages);
        _isLoadingProjectImages = false;
      });
    }
  }

  bool _isProjectImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  String? _defaultProjectImage(List<String> images) {
    if (_selectedImagePath != null || _isEditMode) {
      return _selectedImagePath;
    }
    const preferredImages = <String>[
      'images/unnamed (1).png',
      'images/unnamed.png',
      'images/unnamed (5).png',
    ];
    for (final image in preferredImages) {
      if (images.contains(image)) {
        return image;
      }
    }
    return images.isNotEmpty ? images.first : null;
  }

  Future<void> _openProjectImagePicker() async {
    if (_isLoadingProjectImages) {
      return;
    }

    if (_projectImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images found in the project images folder'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9E2EC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'images/ Folder',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select one image from the bundled project assets',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        itemCount: _projectImages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.88,
                            ),
                        itemBuilder: (context, index) {
                          final imagePath = _projectImages[index];
                          final isSelected = imagePath == _selectedImagePath;

                          return InkWell(
                            onTap: () => Navigator.pop(context, imagePath),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE5EAF1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(19),
                                      ),
                                      child: Container(
                                        color: const Color(0xFFF8FAFC),
                                        padding: const EdgeInsets.all(12),
                                        child: Image.asset(
                                          imagePath,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _displayImageName(imagePath),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.accentColor,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedImagePath = selected;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint = _isEditMode ? 'update_product.php' : 'add_product.php';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/$endpoint'),
      );

      if (_isEditMode) {
        request.fields['id'] = widget.product!.id.toString();
        request.fields['existing_image_url'] = widget.product!.imageUrl;
      }

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descController.text;
      request.fields['price'] = _priceController.text;
      request.fields['category'] = _selectedCategory!;
      request.fields['is_available'] = _isAvailable ? '1' : '0';

      final selectedImageUrl =
          _selectedImagePath ?? _defaultProjectImage(_projectImages);
      if (selectedImageUrl != null && selectedImageUrl.isNotEmpty) {
        request.fields['image_url'] = selectedImageUrl;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Restaurant updated successfully!'
                    : 'Restaurant added successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(
          result['error'] ??
              (_isEditMode
                  ? 'Failed to update restaurant'
                  : 'Failed to add restaurant'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Restaurant' : 'Add New Restaurant',
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Restaurant Name',
                _nameController,
                'e.g. Urban Patty',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Description',
                _descController,
                'Short description...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Starting Price (\$)',
                      _priceController,
                      '0.00',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isFetchingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _categories.map((String category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                                validator: (value) =>
                                    value == null ? 'Required' : null,
                                hint: const Text('Select'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAvailabilityField(),
              const SizedBox(height: 20),
              const Text(
                'Restaurant Image',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedImagePath != null
                    ? 'Selected: ${_displayImageName(_selectedImagePath!)}'
                    : 'Choose an image from the project images folder',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openProjectImagePicker,
                child: Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openProjectImagePicker,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Choose From Project Images'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: Color(0xFFFFD6BE)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildProjectImagesFolder(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode ? 'Save Changes' : 'Create Restaurant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildAvailabilityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isAvailable
                  ? const Color(0xFFFFD7C2)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Text(
                _isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: _isAvailable
                      ? const Color(0xFF95A3B8)
                      : const Color(0xFFB0BCCA),
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                toggled: _isAvailable,
                label: 'Restaurant availability',
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAvailable = !_isAvailable;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 58,
                    height: 32,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isAvailable
                          ? AppTheme.primaryColor
                          : const Color(0xFFD6DEE8),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isAvailable
                                      ? AppTheme.primaryColor
                                      : const Color(0xFF94A3B8))
                                  .withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: _isAvailable
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_isLoadingProjectImages) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_selectedImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_selectedImagePath!, fit: BoxFit.cover),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentImageUrl = widget.product?.imageUrl;
    if (_isEditMode && currentImageUrl != null && currentImageUrl.isNotEmpty) {
      final imageWidget = currentImageUrl.startsWith('uploads/')
          ? Image.network(
              '${AuthService.baseUrl.replaceAll('/api', '')}/$currentImageUrl',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
            )
          : Image.asset(
              currentImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
            );

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageWidget,
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    final hasProjectImages = _projectImages.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          hasProjectImages
              ? 'Tap to choose from project images'
              : 'No images found in images/ folder',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProjectImagesFolder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'images/ Folder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 126,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _buildProjectImagesScroller(),
        ),
      ],
    );
  }

  Widget _buildProjectImagesScroller() {
    if (_isLoadingProjectImages) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_projectImages.isEmpty) {
      return const Center(
        child: Text(
          'No project images available',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      itemCount: _projectImages.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final imagePath = _projectImages[index];
        final isSelected = imagePath == _selectedImagePath;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedImagePath = imagePath;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      width: double.infinity,
                      child: Image.asset(imagePath, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _displayImageName(imagePath),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _displayImageName(String imagePath) {
    return imagePath.replaceFirst('images/', '');
  }
}
