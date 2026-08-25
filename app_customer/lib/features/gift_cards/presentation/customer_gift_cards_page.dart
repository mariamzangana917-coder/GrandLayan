import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/gift_card_design.dart';
import '../data/services/customer_gift_cards_api.dart';
import 'purchase_gift_card_page.dart';

class CustomerGiftCardsPage extends StatefulWidget {
  const CustomerGiftCardsPage({super.key});

  @override
  State<CustomerGiftCardsPage> createState() => _CustomerGiftCardsPageState();
}

class _CustomerGiftCardsPageState extends State<CustomerGiftCardsPage> {
  static const Color _gold = Color(0xFFC9A227);

  final CustomerGiftCardsApi _api = CustomerGiftCardsApi();

  late Future<List<GiftCardDesign>> _designsFuture;

  @override
  void initState() {
    super.initState();
    _designsFuture = _api.getActiveDesigns();
  }

  void _reload() {
    setState(() {
      _designsFuture = _api.getActiveDesigns();
    });
  }

  Future<void> _openPurchasePage(GiftCardDesign design) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PurchaseGiftCardPage(design: design)),
    );

    if (!mounted || created != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم إرسال طلب بطاقة الهدية بنجاح.',
            textAlign: TextAlign.right,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xff121212)
        : const Color(0xffF5F5F5);

    final surfaceColor = isDark ? const Color(0xff1E1E1E) : Colors.white;

    final primaryTextColor = isDark
        ? const Color(0xffEAEAEA)
        : const Color(0xff1C1C1C);

    final secondaryTextColor = isDark
        ? const Color(0xff9CA3AF)
        : const Color(0xff6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "بطاقات الهدايا",
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<List<GiftCardDesign>>(
            future: _designsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _gold),
                );
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  message: snapshot.error.toString(),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onRetry: _reload,
                );
              }

              final designs = snapshot.data ?? const <GiftCardDesign>[];

              if (designs.isEmpty) {
                return _EmptyState(
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onRetry: _reload,
                );
              }

              return RefreshIndicator(
                color: _gold,
                onRefresh: () async {
                  _reload();
                  await _designsFuture;
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final design = designs[index];

                          return _GiftCardItem(
                            design: design,
                            surfaceColor: surfaceColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            onTap: () => _openPurchasePage(design),
                          );
                        }, childCount: designs.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: .64,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GiftCardItem extends StatelessWidget {
  const _GiftCardItem({
    required this.design,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  static const Color _gold = Color(0xFFC9A227);

  final GiftCardDesign design;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC9A227).withOpacity(.65),
                const Color(0xFFC9A227).withOpacity(.25),
                Colors.transparent,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 55,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: SizedBox.expand(
                          child: _GiftCardImage(imageUrl: design.imageUrl),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.grey.shade700,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          design.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          design.description ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            color: secondaryTextColor,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          design.formattedAmount,
                          style: GoogleFonts.tajawal(
                            color: _gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  "شراء الآن",
                                  style: GoogleFonts.tajawal(
                                    color: _gold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: _gold,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}

class _GiftCardImage extends StatelessWidget {
  const _GiftCardImage({required this.imageUrl});

  static const Color _gold = Color(0xFFC9A227);

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: _gold.withOpacity(.08),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: _gold.withOpacity(.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 38,
        color: _gold,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onRetry,
  });

  static const Color _gold = Color(0xFFC9A227);

  final String message;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _gold, size: 60),

            const SizedBox(height: 16),

            Text(
              "تعذر تحميل بطاقات الهدايا",
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: primaryTextColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text("إعادة المحاولة", style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onRetry,
  });

  static const Color _gold = Color(0xFFC9A227);

  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded, color: _gold, size: 62),

            const SizedBox(height: 18),

            Text(
              "لا توجد بطاقات هدايا حالياً",
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "ستظهر بطاقات الهدايا هنا بعد إضافتها من الإدارة.",
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 20),

            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                "تحديث",
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(foregroundColor: _gold),
            ),
          ],
        ),
      ),
    );
  }
}
