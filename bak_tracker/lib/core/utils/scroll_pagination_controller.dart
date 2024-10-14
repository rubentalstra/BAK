import 'package:flutter/material.dart';

class ScrollPaginationController {
  final int limit;
  final ScrollController scrollController = ScrollController();
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMoreData = true;
  int offset = 0;

  ScrollPaginationController({this.limit = 10});

  // Initialize scroll listener
  void initScrollListener(Function loadMoreCallback) {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent * 0.8 &&
          !isFetchingMore &&
          hasMoreData) {
        loadMoreCallback();
      }
    });
  }

  void dispose() {
    scrollController.dispose();
  }

  void resetPagination() {
    offset = 0;
    hasMoreData = true;
  }

  void setFetchingMore(bool value) {
    isFetchingMore = value;
  }

  void setLoading(bool value) {
    isLoading = value;
  }

  void setHasMoreData(bool value) {
    hasMoreData = value;
  }

  void incrementOffset() {
    offset += limit;
  }
}
