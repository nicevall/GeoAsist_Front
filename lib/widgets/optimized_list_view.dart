// lib/widgets/optimized_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// ✅ PRODUCTION READY: Performance-Optimized ListView for Large Datasets
/// Provides efficient rendering and memory management for lists
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double? itemExtent;
  final int? semanticChildCount;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double cacheExtent;
  final int? itemCacheSize;
  final void Function(int index)? onItemVisible;
  final bool enableLazyLoading;
  final Future<List<T>> Function()? onLoadMore;
  final Widget? loadingIndicator;
  final Widget? emptyStateWidget;
  final String? emptyStateMessage;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemExtent,
    this.semanticChildCount,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.separator,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent = 200.0, // Reduced cache for memory efficiency
    this.itemCacheSize,
    this.onItemVisible,
    this.enableLazyLoading = false,
    this.onLoadMore,
    this.loadingIndicator,
    this.emptyStateWidget,
    this.emptyStateMessage,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>>
    with AutomaticKeepAliveClientMixin {
  
  late ScrollController _scrollController;
  final Set<int> _visibleItems = <int>{};
  bool _isLoadingMore = false;
  List<T> _items = [];
  
  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _scrollController = widget.controller ?? ScrollController();
    
    if (widget.enableLazyLoading) {
      _scrollController.addListener(_onScroll);
    }
    
    if (widget.onItemVisible != null) {
      _scrollController.addListener(_trackVisibleItems);
    }
    
    debugPrint('OptimizedListView: Initialized with ${_items.length} items');
  }

  @override
  void didUpdateWidget(OptimizedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.items != widget.items) {
      setState(() {
        _items = List.from(widget.items);
      });
      debugPrint('OptimizedListView: Updated with ${_items.length} items');
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_isLoadingMore && 
        widget.onLoadMore != null &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _trackVisibleItems() {
    if (widget.onItemVisible == null) return;
    
    // Calculate visible items based on scroll position
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final itemHeight = widget.itemExtent ?? 56.0; // Default height
    
    final startIndex = (scrollOffset / itemHeight).floor();
    final endIndex = ((scrollOffset + viewportHeight) / itemHeight).ceil();
    
    for (int i = startIndex; i <= endIndex && i < _items.length; i++) {
      if (i >= 0 && !_visibleItems.contains(i)) {
        _visibleItems.add(i);
        widget.onItemVisible!(i);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final newItems = await widget.onLoadMore!();
      setState(() {
        _items.addAll(newItems);
        _isLoadingMore = false;
      });
      
      debugPrint('OptimizedListView: Loaded ${newItems.length} more items');
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      debugPrint('OptimizedListView: Failed to load more items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Show empty state if no items
    if (_items.isEmpty && !_isLoadingMore) {
      return _buildEmptyState();
    }
    
    // Build optimized list
    if (widget.separator != null) {
      return _buildSeparatedList();
    } else {
      return _buildRegularList();
    }
  }

  Widget _buildEmptyState() {
    if (widget.emptyStateWidget != null) {
      return widget.emptyStateWidget!;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyStateMessage ?? 'No items to display',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegularList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemExtent: widget.itemExtent,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      semanticChildCount: widget.semanticChildCount ?? _items.length,
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index >= _items.length) {
          return _buildLoadingIndicator();
        }
        
        return _buildOptimizedItem(context, index);
      },
    );
  }

  Widget _buildSeparatedList() {
    return ListView.separated(
      controller: _scrollController,
      itemCount: _items.length,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      itemBuilder: (context, index) => _buildOptimizedItem(context, index),
      separatorBuilder: (context, index) => widget.separator!,
    );
  }

  Widget _buildOptimizedItem(BuildContext context, int index) {
    final item = _items[index];
    
    // Wrap item in performance optimization widgets
    Widget itemWidget = widget.itemBuilder(context, item, index);
    
    // Add repaint boundary if enabled and item extent is known
    if (widget.addRepaintBoundaries && widget.itemExtent != null) {
      itemWidget = RepaintBoundary(child: itemWidget);
    }
    
    // Add automatic keep alive if enabled
    if (widget.addAutomaticKeepAlives) {
      itemWidget = AutomaticKeepAlive(child: itemWidget);
    }
    
    // Add semantic index if enabled
    if (widget.addSemanticIndexes) {
      itemWidget = IndexedSemantics(
        index: index,
        child: itemWidget,
      );
    }
    
    return itemWidget;
  }

  Widget _buildLoadingIndicator() {
    return widget.loadingIndicator ?? 
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  @override
  bool get wantKeepAlive => true;
}

/// High-performance grid view for large datasets
class OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final double cacheExtent;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.cacheExtent = 200.0,
  });

  @override
  State<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>> {
  
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('No items to display'),
      );
    }

    return GridView.builder(
      controller: widget.controller,
      itemCount: widget.items.length,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      cacheExtent: widget.cacheExtent,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        
        // Wrap in performance optimization widgets
        return RepaintBoundary(
          child: IndexedSemantics(
            index: index,
            child: widget.itemBuilder(context, item, index),
          ),
        );
      },
    );
  }
}

/// Optimized page view for better memory management
class OptimizedPageView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final PageController? controller;
  final ScrollPhysics? physics;
  final bool allowImplicitScrolling;
  final void Function(int index)? onPageChanged;
  final bool enablePreloading;

  const OptimizedPageView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.physics,
    this.allowImplicitScrolling = false,
    this.onPageChanged,
    this.enablePreloading = true,
  });

  @override
  State<OptimizedPageView<T>> createState() => _OptimizedPageViewState<T>();
}

class _OptimizedPageViewState<T> extends State<OptimizedPageView<T>> {
  late PageController _pageController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = widget.controller ?? PageController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('No items to display'),
      );
    }

    return PageView.builder(
      controller: _pageController,
      physics: widget.physics,
      allowImplicitScrolling: widget.allowImplicitScrolling,
      onPageChanged: _onPageChanged,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        
        // Only build pages that are visible or adjacent (for preloading)
        if (widget.enablePreloading) {
          final isVisible = (index - _currentIndex).abs() <= 1;
          if (!isVisible) {
            return Container(); // Empty container for non-visible pages
          }
        }
        
        return RepaintBoundary(
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}

/// Performance monitoring widget for lists
class ListPerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String listName;
  final bool enableMonitoring;

  const ListPerformanceMonitor({
    super.key,
    required this.child,
    required this.listName,
    this.enableMonitoring = kDebugMode,
  });

  @override
  State<ListPerformanceMonitor> createState() => _ListPerformanceMonitorState();
}

class _ListPerformanceMonitorState extends State<ListPerformanceMonitor> {
  int _buildCount = 0;
  DateTime? _lastBuild;

  @override
  Widget build(BuildContext context) {
    if (widget.enableMonitoring) {
      _buildCount++;
      final now = DateTime.now();
      
      if (_lastBuild != null) {
        final timeSinceLastBuild = now.difference(_lastBuild!);
        debugPrint('ListPerformanceMonitor [${widget.listName}]: '
            'Build #$_buildCount, Time since last: ${timeSinceLastBuild.inMilliseconds}ms');
      }
      
      _lastBuild = now;
    }

    return widget.child;
  }
}