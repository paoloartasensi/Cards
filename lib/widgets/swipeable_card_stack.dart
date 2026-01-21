import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';

/// A swipeable card stack widget with curved swipe effect
class SwipeableCardStack extends StatefulWidget {
  final List<CardModel> cards;
  final Function(CardModel card)? onCardTap;
  final Function(CardModel card)? onCardLongPress;
  final Function(CardModel card, int newIndex)? onCardSwiped;

  const SwipeableCardStack({
    super.key,
    required this.cards,
    this.onCardTap,
    this.onCardLongPress,
    this.onCardSwiped,
  });

  @override
  State<SwipeableCardStack> createState() => _SwipeableCardStackState();
}

class _SwipeableCardStackState extends State<SwipeableCardStack>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _returnController;
  late AnimationController _shakeController;
  
  // Current drag state
  double _dragX = 0;
  double _dragStartX = 0;
  bool _isDragging = false;
  int _topCardIndex = 0;
  
  // For swipe left animation - showing incoming card from right
  bool _isSwipingLeft = false;
  
  // Card dimensions
  static const double _cardHeight = 180.0;
  static const double _cardPeekOffset = 25.0;
  static const double _cardScaleDecrement = 0.03;
  
  // Swipe threshold (percentage of screen width)
  static const double _swipeThreshold = 0.25;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Shake animation on appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playShakeAnimation();
    });
  }
  
  void _playShakeAnimation() {
    HapticFeedback.lightImpact();
    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _returnController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _isDragging = true;
    _returnController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragX = details.localPosition.dx - _dragStartX;
      // Track if swiping left to show incoming card
      _isSwipingLeft = _dragX < 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final swipePercentage = _dragX.abs() / screenWidth;
    final velocity = details.velocity.pixelsPerSecond.dx;

    // Determine if swipe should complete
    if (swipePercentage > _swipeThreshold || velocity.abs() > 800) {
      _completeSwipe(_dragX > 0 ? 1 : -1, velocity);
    } else {
      _returnToCenter();
    }
  }

  void _completeSwipe(int direction, double velocity) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = direction * (screenWidth + 100);
    
    // Create curved animation for exit - different curves for each direction
    final curved = CurvedAnimation(
      parent: _swipeController,
      // Swipe left (bringing back): smooth deceleration, no bounce
      // Swipe right (sending away): ease out cubic for natural exit
      curve: direction < 0 ? Curves.easeOut : Curves.easeOutCubic,
    );
    
    final startX = _dragX;
    final wasSwipingLeft = direction < 0;
    bool hapticTriggered = false;
    
    _swipeController.reset();
    _swipeController.addListener(() {
      final animValue = curved.value;
      setState(() {
        _dragX = startX + (targetX - startX) * animValue;
        _isSwipingLeft = wasSwipingLeft;
      });
      
      // Trigger haptic when incoming card reaches ~90% of its journey (lands on stack)
      if (wasSwipingLeft && !hapticTriggered && animValue > 0.9) {
        hapticTriggered = true;
        HapticFeedback.mediumImpact();
      }
    });
    
    _swipeController.forward().then((_) {
      // Haptic for swipe right (card leaving) - at the end
      if (!wasSwipingLeft) {
        HapticFeedback.lightImpact();
      }
      
      setState(() {
        _dragX = 0;
        _isSwipingLeft = false;
        if (widget.cards.isNotEmpty) {
          if (direction > 0) {
            // Swipe RIGHT: send card to back
            _topCardIndex = (_topCardIndex + 1) % widget.cards.length;
          } else {
            // Swipe LEFT: bring back previous card
            _topCardIndex = (_topCardIndex - 1 + widget.cards.length) % widget.cards.length;
          }
          widget.onCardSwiped?.call(
            widget.cards[_topCardIndex], 
            _topCardIndex,
          );
        }
      });
      _swipeController.removeListener(() {});
    });
  }

  void _returnToCenter() {
    // Use spring physics for natural bounce back
    final startX = _dragX;
    
    _returnController.reset();
    _returnController.addListener(() {
      // Spring-like return
      final t = Curves.elasticOut.transform(_returnController.value);
      setState(() {
        _dragX = startX * (1 - t);
        if (_dragX.abs() < 1) _isSwipingLeft = false;
      });
    });
    
    _returnController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final maxCards = math.min(widget.cards.length, 4);
    
    // Calculate swipe progress for incoming card (only when swiping left)
    final swipeLeftProgress = _isSwipingLeft ? (_dragX.abs() / screenWidth).clamp(0.0, 1.0) : 0.0;
    
    return SizedBox(
      height: _cardHeight + (_cardPeekOffset * (maxCards - 1)) + 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Regular stack cards
          ...List.generate(maxCards, (stackIndex) {
            // Map stack index to actual card index
            final actualIndex = (_topCardIndex + (maxCards - 1 - stackIndex)) % widget.cards.length;
            final card = widget.cards[actualIndex];
            final isTopCard = stackIndex == maxCards - 1;
            
            // Calculate position and scale based on stack position
            final baseOffset = stackIndex * _cardPeekOffset;
            final scale = 1.0 - ((maxCards - 1 - stackIndex) * _cardScaleDecrement);
            
            // Apply drag transformation only to top card
            double xOffset = 0;
            double rotation = 0;
            double yOffset = baseOffset;
            double currentScale = scale;
            
            if (isTopCard) {
              xOffset = _dragX;
              // Rotation based on drag (max 15 degrees)
              rotation = (_dragX / screenWidth) * 0.26; // ~15 degrees in radians
              
              // Subtle arc - move up slightly during swipe
              final swipeProgress = (_dragX.abs() / screenWidth).clamp(0.0, 1.0);
              yOffset = baseOffset - (swipeProgress * 20);
            } else if (stackIndex == maxCards - 2 && _dragX > 0) {
              // Second card scales up as top card is dragged RIGHT (sending to back)
              final swipeProgress = (_dragX / screenWidth).clamp(0.0, 1.0);
              currentScale = scale + (swipeProgress * _cardScaleDecrement);
              yOffset = baseOffset - (swipeProgress * _cardPeekOffset * 0.5);
            }
            
            return AnimatedPositioned(
              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              top: yOffset,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  double animatedShakeOffset = 0;
                  if (isTopCard && !_isDragging && _dragX == 0) {
                    final shakeProgress = _shakeController.value;
                    animatedShakeOffset = math.sin(shakeProgress * math.pi * 4) * (1 - shakeProgress) * 12;
                  }
                  
                  return GestureDetector(
                    onPanStart: isTopCard ? _onPanStart : null,
                    onPanUpdate: isTopCard ? _onPanUpdate : null,
                    onPanEnd: isTopCard ? _onPanEnd : null,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(currentScale, currentScale, 1.0)
                        ..setEntry(0, 3, (xOffset + animatedShakeOffset) * currentScale)
                        ..rotateZ(rotation),
                      child: Opacity(
                        opacity: isTopCard ? 1.0 : (0.6 + (stackIndex * 0.15)).clamp(0.0, 1.0),
                        child: _buildCard(card, isTopCard),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Incoming card from RIGHT (only when swiping left)
          if (_isSwipingLeft && widget.cards.length > 1)
            _buildIncomingCard(maxCards, swipeLeftProgress, screenWidth),
        ],
      ),
    );
  }
  
  Widget _buildIncomingCard(int maxCards, double progress, double screenWidth) {
    // The card that will become the new top (previous card in list)
    final previousIndex = (_topCardIndex - 1 + widget.cards.length) % widget.cards.length;
    final card = widget.cards[previousIndex];
    
    // Start from right side and slide in with arc motion
    final topPosition = (maxCards - 1) * _cardPeekOffset;
    final startX = screenWidth + 50;
    final endX = 0.0;
    final currentX = startX + (progress * (endX - startX));
    
    // Arc motion - card comes up then settles down (like the outgoing card but reversed)
    final arcOffset = math.sin(progress * math.pi) * 20;
    final yOffset = topPosition - arcOffset;
    
    // Rotation that matches the arc - starts rotated, ends straight
    final rotation = (1 - progress) * -0.26; // Same max rotation as outgoing card
    
    return Positioned(
      top: yOffset,
      left: currentX,
      right: -currentX,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(rotation),
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: _buildCard(card, false),
        ),
      ),
    );
  }

  Widget _buildCard(CardModel card, bool isTopCard) {
    return GestureDetector(
      onTap: isTopCard ? () => widget.onCardTap?.call(card) : null,
      onLongPress: isTopCard ? () => widget.onCardLongPress?.call(card) : null,
      child: Container(
        height: _cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(card.colorValue),
              Color(card.colorValue).withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(card.colorValue).withValues(alpha: isTopCard ? 0.4 : 0.2),
              blurRadius: isTopCard ? 20 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background circle decoration
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CardCategories.getIcon(card.category),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                card.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Show flight info for Voli category, otherwise show barcode info
                    if (card.category == CardCategories.voli && 
                        (card.flightRoute != null || card.flightDate != null)) ...[
                      if (card.flightRoute != null)
                        Text(
                          card.flightRoute!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (card.flightNumber != null) ...[
                            Text(
                              card.flightNumber!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (card.flightDate != null)
                            Text(
                              '${card.flightDate!.day.toString().padLeft(2, '0')}/${card.flightDate!.month.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          if (card.departureTime != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${card.departureTime}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Text(
                        BarcodeTypes.getDisplayName(card.codeType),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.code,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
