import 'package:flutter/material.dart';

import '../data/gift_card.dart';
import '../data/gift_card_service.dart';
import 'add_gift_card_screen.dart';

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen> {
  static const Color _gold = Color(0xFFC9A227);

  final GiftCardService _service = const GiftCardService();

  List<GiftCard> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _busyIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadGiftCards();
  }

  Future<void> _loadGiftCards() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _service.fetchGiftCards();

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on GiftCardException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع أثناء تحميل البطاقات.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
    final surfaceColor = widget.isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final primaryTextColor = widget.isDarkMode
        ? const Color(0xFFEAEAEA)
        : const Color(0xFF1C1C1C);
    final secondaryTextColor = widget.isDarkMode
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final borderColor = widget.isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: 19,
          ),
        ),
        title: Text(
          'بطاقات الهدايا',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddGiftCard,
        backgroundColor: _gold,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text(
          'إضافة بطاقة',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: _buildSummaryCard(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              Expanded(
                child: _buildContent(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: secondaryTextColor,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadGiftCards,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadGiftCards,
        color: _gold,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 110),
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              color: secondaryTextColor,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بطاقات هدايا',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'أضيفي أول بطاقة هدية لتظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGiftCards,
      color: _gold,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          final isBusy = _busyIds.contains(item.id);

          return _GiftCardTile(
            item: item,
            imageUrl: _service.buildImageUrl(item.imagePath),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            isBusy: isBusy,
            onEdit: isBusy ? null : () => _openEditGiftCard(item),
            onDelete: isBusy ? null : () => _confirmDelete(item),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final activeCount = _items.where((item) => item.isActive).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: _gold,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة بطاقات الهدايا',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'إضافة البطاقات وتعديل أسعارها وحالتها',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$activeCount مفعلة',
              style: const TextStyle(
                color: _gold,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddGiftCard() async {
    final created = await Navigator.of(context).push<GiftCard>(
      MaterialPageRoute<GiftCard>(
        builder: (context) {
          return AddGiftCardScreen(isDarkMode: widget.isDarkMode);
        },
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() {
      _items = <GiftCard>[
        created,
        ..._items.where((item) => item.id != created.id),
      ];
    });

    _showMessage('تمت إضافة بطاقة الهدية بنجاح.');
  }

  void _openEditGiftCard(GiftCard item) {
    _showMessage('سنربط تعديل بطاقة ${item.name} بالخطوة التالية.');
  }

  Future<void> _confirmDelete(GiftCard item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'حذف البطاقة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: Text(
              'هل تريدين حذف بطاقة "${item.name}"؟',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (result != true || !mounted) return;

    setState(() => _busyIds.add(item.id));

    try {
      await _service.deleteGiftCard(item.id);

      if (!mounted) return;

      setState(() {
        _items.removeWhere((element) => element.id == item.id);
        _busyIds.remove(item.id);
      });

      _showMessage('تم حذف بطاقة الهدية بنجاح.');
    } on GiftCardException catch (error) {
      if (!mounted) return;

      setState(() => _busyIds.remove(item.id));
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      setState(() => _busyIds.remove(item.id));
      _showMessage('تعذر حذف بطاقة الهدية.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _GiftCardTile extends StatelessWidget {
  const _GiftCardTile({
    required this.item,
    required this.imageUrl,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _gold = Color(0xFFC9A227);

  final GiftCard item;
  final String? imageUrl;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBusy ? 0.70 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 142,
              height: 108,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(
                  color: _gold.withValues(alpha: 0.08),
                  child: imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: _gold,
                            size: 34,
                          ),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: _gold,
                                size: 31,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatAmount(item.amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 11),
                  _InfoRow(
                    icon: Icons.event_available_outlined,
                    text: 'صالحة لمدة ${item.validityDays} يوم',
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.receipt_long_outlined,
                    text: '${item.ordersCount} طلب',
                    color: secondaryTextColor,
                  ),
                  if (isBusy) ...[
                    const SizedBox(height: 10),
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: _gold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: PopupMenuButton<_GiftCardAction>(
                enabled: !isBusy,
                tooltip: 'خيارات البطاقة',
                color: surfaceColor,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: secondaryTextColor,
                  size: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _GiftCardAction.edit:
                      onEdit?.call();
                      break;
                    case _GiftCardAction.delete:
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_GiftCardAction>(
                    value: _GiftCardAction.edit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, color: _gold, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'تعديل',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_GiftCardAction>(
                    value: _GiftCardAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'حذف',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < value.length; index++) {
      final remaining = value.length - index;
      buffer.write(value[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return '$buffer د.ع';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

enum _GiftCardAction { edit, delete }
