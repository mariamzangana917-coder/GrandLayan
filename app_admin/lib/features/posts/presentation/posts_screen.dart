import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../data/post_model.dart';
import '../data/post_service.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService _postService = PostService();
  final ImagePicker _imagePicker = ImagePicker();

  String _department = 'salon';

  List<PostModel> _posts = <PostModel>[];

  bool _isLoading = true;
  bool _isUploading = false;

  /// يمنع الضغط المتكرر على نفس المنشور أثناء تنفيذ العملية.
  final Set<int> _busyPostIds = <int>{};

  /// يمنع استجابة طلب قديم من الكتابة فوق نتائج القسم الحالي.
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final int requestId = ++_loadRequestId;
    final String department = _department;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<PostModel> posts = await _postService.fetchPosts(
        department: department,
      );

      if (!mounted || requestId != _loadRequestId) {
        return;
      }

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _loadRequestId) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted || requestId != _loadRequestId) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('تعذر تحميل المنشورات.');
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) {
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return;
      }

      final File image = File(pickedFile.path);

      if (!await image.exists()) {
        if (!mounted) return;

        _showMessage('تعذر الوصول إلى الصورة.');
        return;
      }

      if (!mounted) {
        return;
      }

      final String? description = await _showDescriptionDialog();

      if (!mounted) {
        return;
      }

      if (description == null) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final PostModel post = await _postService.createPost(
        department: _department,
        image: image,
        description: description,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _posts.insert(0, post);
        _isUploading = false;
      });

      _showMessage('تمت إضافة المنشور بنجاح.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
      });

      _showMessage('تعذر إضافة المنشور.');
    }
  }

  Future<String?> _showDescriptionDialog({String initialDescription = ''}) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _PostDescriptionDialog(
          initialDescription: initialDescription,
          isDarkMode: widget.isDarkMode,
        );
      },
    );
  }

  Future<void> _replacePostImage(PostModel post) async {
    if (_busyPostIds.contains(post.id)) {
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return;
      }

      final File image = File(pickedFile.path);

      if (!await image.exists()) {
        if (!mounted) return;

        _showMessage('تعذر الوصول إلى الصورة.');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _busyPostIds.add(post.id);
      });

      final PostModel updatedPost = await _postService.replacePostImage(
        postId: post.id,
        image: image,
      );

      if (!mounted) {
        return;
      }

      final int index = _posts.indexWhere((item) => item.id == post.id);

      if (index != -1) {
        setState(() {
          _posts[index] = updatedPost;
        });
      }

      _showMessage('تم تغيير صورة المنشور بنجاح.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('تعذر تغيير صورة المنشور.');
    } finally {
      if (mounted) {
        setState(() {
          _busyPostIds.remove(post.id);
        });
      }
    }
  }

  Future<void> _editPostDescription(PostModel post) async {
    if (_busyPostIds.contains(post.id)) {
      return;
    }

    final String? description = await _showDescriptionDialog(
      initialDescription: post.description ?? '',
    );

    if (!mounted || description == null) {
      return;
    }

    setState(() {
      _busyPostIds.add(post.id);
    });

    try {
      final PostModel updatedPost = await _postService.updatePostDescription(
        postId: post.id,
        description: description.isEmpty ? null : description,
      );

      if (!mounted) {
        return;
      }

      final int index = _posts.indexWhere((item) => item.id == post.id);

      if (index != -1) {
        setState(() {
          _posts[index] = updatedPost;
        });
      }

      _showMessage('تم تحديث وصف المنشور بنجاح.');
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر تحديث وصف المنشور.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyPostIds.remove(post.id);
        });
      }
    }
  }

  Future<void> _togglePostStatus(PostModel post) async {
    if (_busyPostIds.contains(post.id)) {
      return;
    }

    setState(() {
      _busyPostIds.add(post.id);
    });

    try {
      final PostModel updatedPost = await _postService.updatePostStatus(
        postId: post.id,
        isActive: !post.isActive,
      );

      if (!mounted) return;

      final int index = _posts.indexWhere((item) => item.id == post.id);

      if (index != -1) {
        setState(() {
          _posts[index] = updatedPost;
        });
      }

      _showMessage(
        updatedPost.isActive ? 'تم تفعيل المنشور.' : 'تم إيقاف المنشور.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('تعذر تحديث حالة المنشور.');
    } finally {
      if (mounted) {
        setState(() {
          _busyPostIds.remove(post.id);
        });
      }
    }
  }

  Future<void> _deletePost(PostModel post) async {
    if (_busyPostIds.contains(post.id)) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final bool isDarkMode = widget.isDarkMode;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF171717) : Colors.white,
          title: Text(
            'حذف المنشور',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : const Color(0xFF171717),
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف هذا المنشور؟\nلا يمكن التراجع عن هذه العملية.',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              height: 1.6,
              color: isDarkMode
                  ? const Color(0xFFB5B5B5)
                  : const Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busyPostIds.add(post.id);
    });

    try {
      await _postService.deletePost(postId: post.id);

      if (!mounted) return;

      setState(() {
        _posts.removeWhere((item) => item.id == post.id);
      });

      _showMessage('تم حذف المنشور بنجاح.');
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('تعذر حذف المنشور.');
    } finally {
      if (mounted) {
        setState(() {
          _busyPostIds.remove(post.id);
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;

    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final Color cardColor = isDarkMode
        ? const Color(0xFF111111)
        : const Color(0xFFF8F8F8);

    final Color borderColor = isDarkMode
        ? const Color(0xFF292929)
        : const Color(0xFFEAEAEA);

    final Color primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    final Color secondaryTextColor = isDarkMode
        ? const Color(0xFFB5B5B5)
        : const Color(0xFF777777);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'آخر المنشورات',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadPosts,
            tooltip: 'تحديث',
            icon: Icon(Icons.refresh_rounded, color: secondaryTextColor),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          color: const Color(0xFFB89552),
          onRefresh: _loadPosts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              _buildDepartmentSelector(
                primaryTextColor: primaryTextColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 18),
              _buildAddPostButton(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _department == 'salon'
                          ? 'منشورات الصالون'
                          : 'منشورات العيادة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  Text(
                    '${_posts.length} منشور',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              if (_isLoading)
                _buildLoadingState()
              else if (_posts.isEmpty)
                _buildEmptyState(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                )
              else
                _buildPostsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentSelector({
    required Color primaryTextColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDepartmentButton(
              value: 'salon',
              title: 'الصالون',
              icon: Icons.spa_outlined,
              primaryTextColor: primaryTextColor,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildDepartmentButton(
              value: 'clinic',
              title: 'العيادة',
              icon: Icons.medical_services_outlined,
              primaryTextColor: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentButton({
    required String value,
    required String title,
    required IconData icon,
    required Color primaryTextColor,
  }) {
    final bool selected = _department == value;

    return Material(
      color: selected ? const Color(0xFFB89552) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isUploading
            ? null
            : () {
                if (_department == value) {
                  return;
                }

                setState(() {
                  _department = value;
                  _posts = <PostModel>[];
                });

                _loadPosts();
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : primaryTextColor,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPostButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF171717),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF555555),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isUploading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_photo_alternate_outlined, size: 21),
        label: Text(
          _isUploading ? 'جارٍ نشر الصورة...' : 'إضافة منشور',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final PostModel post = _posts[index];

        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    final bool isBusy = _busyPostIds.contains(post.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Container(
        color: widget.isDarkMode
            ? const Color(0xFF111111)
            : const Color(0xFFF5F5F5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFB89552),
                    size: 34,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFB89552),
                  ),
                );
              },
            ),

            // طبقة خفيفة حتى تكون أزرار الإدارة واضحة.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 82,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 9,
              right: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  post.isActive ? 'نشط' : 'غير نشط',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            if (post.description != null && post.description!.trim().isNotEmpty)
              Positioned(
                left: 10,
                right: 10,
                bottom: 48,
                child: Text(
                  post.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: _buildPostActionButton(
                      icon: post.isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      label: post.isActive ? 'إخفاء' : 'تفعيل',
                      onPressed: isBusy ? null : () => _togglePostStatus(post),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildPostDescriptionButton(
                    isBusy: isBusy,
                    onPressed: isBusy ? null : () => _editPostDescription(post),
                  ),
                  const SizedBox(width: 6),

                  _buildPostImageButton(
                    isBusy: isBusy,
                    onPressed: isBusy ? null : () => _replacePostImage(post),
                  ),
                  const SizedBox(width: 6),
                  _buildPostDeleteButton(
                    isBusy: isBusy,
                    onPressed: isBusy ? null : () => _deletePost(post),
                  ),
                ],
              ),
            ),

            if (isBusy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFB89552),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 34,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.62),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.42),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPostDescriptionButton({
    required bool isBusy,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: 'تعديل الوصف',
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.62),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.edit_note_outlined, size: 19),
      ),
    );
  }

  Widget _buildPostImageButton({
    required bool isBusy,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: 'تغيير الصورة',
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.62),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.photo_camera_outlined, size: 18),
      ),
    );
  }

  Widget _buildPostDeleteButton({
    required bool isBusy,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.62),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 260,
      child: Center(child: CircularProgressIndicator(color: Color(0xFFB89552))),
    );
  }

  Widget _buildEmptyState({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFB89552).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Color(0xFFB89552),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد منشورات حالياً',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'أضف أول منشور لهذا القسم من الزر أعلاه.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

class _PostDescriptionDialog extends StatefulWidget {
  const _PostDescriptionDialog({
    required this.initialDescription,
    required this.isDarkMode,
  });

  final String initialDescription;
  final bool isDarkMode;

  @override
  State<_PostDescriptionDialog> createState() => _PostDescriptionDialogState();
}

class _PostDescriptionDialogState extends State<_PostDescriptionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialDescription.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF171717)
          : Colors.white,
      title: Text(
        isEditing ? 'تعديل وصف المنشور' : 'وصف المنشور',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: widget.isDarkMode ? Colors.white : const Color(0xFF171717),
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 500,
        maxLines: 5,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'اكتب وصف المنشور...',
          hintTextDirection: TextDirection.rtl,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
