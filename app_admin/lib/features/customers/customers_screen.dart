import 'dart:async';
import '../../core/network/api_url.dart';
import 'package:flutter/material.dart';

import 'data/customer_model.dart';
import 'data/customer_service.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  static const Color _gold = Color(0xFFB89552);

  final CustomerService _service = const CustomerService();

  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  final List<AdminCustomer> _customers = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _lastPage = 1;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _service.fetchCustomers(
        search: _searchController.text,
        page: 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _customers
          ..clear()
          ..addAll(result.customers);

        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _isLoading = false;
      });
    } on CustomerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل العملاء.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _service.fetchCustomers(
        search: _searchController.text,
        page: _currentPage + 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _customers.addAll(result.customers);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _isLoadingMore = false;
      });
    } on CustomerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });

      _showMessage('تعذر تحميل المزيد من العملاء.');
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});

    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadCustomers(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final cardColor = isDarkMode
        ? const Color(0xFF111111)
        : const Color(0xFFF8F8F8);

    final borderColor = isDarkMode
        ? const Color(0xFF414141)
        : const Color(0xFFCFCFCF);

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    final secondaryTextColor = isDarkMode
        ? const Color(0xFFC2C2C2)
        : const Color(0xFF666666);

    final fieldColor = isDarkMode
        ? const Color(0xFF141414)
        : const Color(0xFFF7F4EE);

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        color: _gold,
        onRefresh: () => _loadCustomers(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ابحثي باسم العميلة أو رقم الهاتف',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: secondaryTextColor,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  _loadCustomers(refresh: true);
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: fieldColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _gold,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_total عميلة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: _gold)),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(
                  message: _errorMessage!,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
              )
            else if (_customers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                sliver: SliverList.separated(
                  itemCount: _customers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildCustomerCard(
                      customer: _customers[index],
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  },
                ),
              ),
            if (!_isLoading &&
                _errorMessage == null &&
                _customers.isNotEmpty &&
                _currentPage < _lastPage)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: OutlinedButton(
                    onPressed: _isLoadingMore ? null : _loadMore,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: _gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _gold,
                            ),
                          )
                        : const Text('تحميل المزيد'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard({
    required AdminCustomer customer,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => CustomerDetailsScreen(
                customerId: customer.id,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );

          if (mounted) {
            await _loadCustomers(refresh: true);
          }
        },
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: borderColor, width: 0.9),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(
                customer: customer,
                primaryTextColor: primaryTextColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(customer.isActive),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 17,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customer.phone ?? 'رقم الهاتف غير متوفر',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMetric(
                            label: 'الحجوزات',
                            value: customer.appointmentsCount.toString(),
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ),
                        Container(width: 1, height: 28, color: borderColor),
                        Expanded(
                          child: _buildSmallMetric(
                            label: 'آخر موعد',
                            value: _formatShortDate(customer.lastAppointmentAt),
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required AdminCustomer customer,
    required Color primaryTextColor,
  }) {
    final String firstLetter = customer.name.isNotEmpty
        ? customer.name.characters.first
        : 'ع';

    final String? avatarUrl = ApiUrl.resolveStorageUrl(customer.avatar);

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: _gold.withValues(alpha: 0.40)),
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? _buildAvatarLetter(firstLetter)
            : Image.network(
                avatarUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return _buildAvatarLetter(firstLetter);
                    },
                loadingBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? loadingProgress,
                    ) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _gold,
                          ),
                        ),
                      );
                    },
              ),
      ),
    );
  }

  Widget _buildAvatarLetter(String letter) {
    return Container(
      alignment: Alignment.center,
      color: _gold.withValues(alpha: 0.14),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _gold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final background = isActive
        ? const Color(0xFFE8F5EC)
        : const Color(0xFFFFE9E9);

    final foreground = isActive
        ? const Color(0xFF1D7A46)
        : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isActive ? 'نشطة' : 'غير نشطة',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildSmallMetric({
    required String label,
    required String value,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: secondaryTextColor)),
      ],
    );
  }

  Widget _buildErrorState({
    required String message,
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 32, color: _gold),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryTextColor),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  _loadCustomers(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required Color cardColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded, size: 36, color: _gold),
              const SizedBox(height: 10),
              Text(
                'لا توجد عميلات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'غيّري الفلترة أو امسحي البحث لعرض نتائج أخرى.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) {
      return 'لا يوجد';
    }

    final local = date.toLocal();

    return '${local.day}/${local.month}/${local.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
