import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/watchlist_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class WatchlistButton extends StatefulWidget {
  final TmdbMovie movie;
  final double size;
  final bool showBackground;

  const WatchlistButton({
    super.key,
    required this.movie,
    this.size = 18,
    this.showBackground = true,
  });

  @override
  State<WatchlistButton> createState() =>
      _WatchlistButtonState();
}

class _WatchlistButtonState extends State<WatchlistButton>
    with SingleTickerProviderStateMixin {
  final WatchlistService _watchlistService =
      WatchlistService();

  bool _isInWatchlist = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  bool _pendingState = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.elasticOut,
      ),
    );
    _checkWatchlist();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkWatchlist() async {
    final inList = await _watchlistService
        .isInWatchlist(widget.movie.id);
    if (mounted) {
      setState(() {
        _isInWatchlist = inList;
        _pendingState = inList;
      });
    }
  }

  void _toggle() {
    if (!mounted) return;

    // 1. Update UI instantly (optimistic)
    final newState = !_isInWatchlist;
    setState(() {
      _isInWatchlist = newState;
      _pendingState = newState;
      _isSaving = true;
    });

    HapticFeedback.lightImpact();

    // 2. Bounce animation
    _animController
        .forward()
        .then((_) => _animController.reverse());

    // 3. Cancel previous debounce
    _debounceTimer?.cancel();

    // 4. Debounce 500ms then save
    // If user taps rapidly only last
    // state gets saved to Firestore
    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        try {
          if (_pendingState) {
            await _watchlistService
                .addToWatchlist(widget.movie);
          } else {
            await _watchlistService
                .removeFromWatchlist(widget.movie.id);
          }

          if (mounted) {
            setState(() => _isSaving = false);

            // Show snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _pendingState
                      ? '${widget.movie.title} added to watchlist'
                      : '${widget.movie.title} removed from watchlist',
                ),
                backgroundColor: _pendingState
                    ? successColor
                    : secondaryColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } catch (e) {
          // Revert UI on failure
          if (mounted) {
            setState(() {
              _isInWatchlist = !_pendingState;
              _pendingState = !_pendingState;
              _isSaving = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Failed to update watchlist',
                ),
                backgroundColor: errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: _toggle,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.showBackground
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isInWatchlist
                      ? appthemecolor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isInWatchlist
                        ? appthemecolor
                        : Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: CircularProgressIndicator(
                          color: _isInWatchlist
                              ? appthemecolor
                              : Colors.white,
                          strokeWidth: 1.5,
                        ),
                      )
                    : Icon(
                        _isInWatchlist
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isInWatchlist
                            ? appthemecolor
                            : Colors.white,
                        size: widget.size,
                      ),
              )
            : _isSaving
                ? SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      color: _isInWatchlist
                          ? appthemecolor
                          : secondaryColor,
                      strokeWidth: 1.5,
                    ),
                  )
                : Icon(
                    _isInWatchlist
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isInWatchlist
                        ? appthemecolor
                        : secondaryColor,
                    size: widget.size,
                  ),
      ),
    );
  }
}