import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/events/presentation/providers/ai_provider.dart';
import 'dart:math' as math;

class AIBottomSheet extends ConsumerStatefulWidget {
  final EventEntity event;
  final bool isDark;

  const AIBottomSheet({
    super.key,
    required this.event,
    required this.isDark,
  });

  @override
  ConsumerState<AIBottomSheet> createState() => _AIBottomSheetState();
}

class _AIBottomSheetState extends ConsumerState<AIBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _generateDescription() {
    ref.read(aiProvider.notifier).generateDescription(
          title: widget.event.title,
          date: widget.event.formattedDate,
          time: widget.event.formattedDayTime,
          duration: widget.event.formattedDuration,
          location: widget.event.location,
          existingDescription: widget.event.description,
        );
  }

  void _generateIdeas() {
    ref.read(aiProvider.notifier).generateIdeas(
          title: widget.event.title,
          date: widget.event.formattedDate,
          location: widget.event.location,
        );
  }

  void _showCopiedNotification() {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
                SizedBox(width: 12),
                Text(
                  'Copied to clipboard!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [
                  Color(0xFF0A0E27),
                  Color(0xFF1A1F3A),
                  Color(0xFF2D1B4E),
                ]
              : [
                  Color(0xFFF8F9FF),
                  Color(0xFFE8ECFF),
                  Color(0xFFDDE3FF),
                ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          _buildParticlesBackground(),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withOpacity(widget.isDark ? 0.1 : 0.2),
                width: 1.5,
              ),
            ),
          ),

          Column(
            children: [
              _buildDragHandle(),
              _buildHeader(),
              _buildGlowingTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDescriptionTab(aiState),
                    _buildIdeasTab(aiState),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticlesBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlesPainter(
            animation: _particleController,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      width: 48,
      height: 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          // Animated AI Icon with Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withOpacity(0.3 + (_pulseController.value * 0.2)),
                      blurRadius: 24 + (_pulseController.value * 8),
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Powered by Gemini 2.5',
                  style: TextStyle(
                    fontSize: 12,
                    color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          _buildGlassButton(
            icon: Icons.close_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(widget.isDark ? 0.08 : 0.3),
        border: Border.all(
          color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: CircleBorder(),
          child: Icon(
            icon,
            color: widget.isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(widget.isDark ? 0.1 : 0.3),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.6),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_rounded, size: 18),
                SizedBox(width: 8),
                Text('Description'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_rounded, size: 18),
                SizedBox(width: 8),
                Text('Ideas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab(AIState aiState) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            icon: Icons.auto_fix_high_rounded,
            text: 'Generate or improve your event description using AI',
          ),
          SizedBox(height: 16),
          if (aiState.isLoading)
            _buildLoadingState()
          else if (aiState.error != null)
            _buildErrorState(aiState.error!)
          else if (aiState.descriptionText != null)
            _buildResultState(aiState.descriptionText!)
          else
            _buildInitialState(
              icon: Icons.auto_awesome_mosaic_rounded,
              title: 'Ready to Create Magic?',
              subtitle: 'Tap the button below to generate\nAI-powered content',
            ),
          SizedBox(height: 16),
          _buildGradientButton(
            onPressed: aiState.isLoading ? null : _generateDescription,
            icon: Icons.auto_awesome_rounded,
           label: aiState.descriptionText == null ? 'Generate Description' : 'Regenerate',
            gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeasTab(AIState aiState) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            icon: Icons.tips_and_updates_rounded,
            text: 'Get creative ideas and suggestions for your event',
          ),
          SizedBox(height: 16),
          if (aiState.isLoading)
            _buildLoadingState()
          else if (aiState.error != null)
            _buildErrorState(aiState.error!)
          else if (aiState.ideasText != null)
            _buildResultState(aiState.ideasText!)
          else
            _buildInitialState(
              icon: Icons.emoji_objects_rounded,
              title: 'Spark Your Creativity',
              subtitle: 'Get innovative ideas to make\nyour event unforgettable',
            ),
          SizedBox(height: 16),
          _buildGradientButton(
            onPressed: aiState.isLoading ? null : _generateIdeas,
            icon: Icons.lightbulb_rounded,
            label: aiState.ideasText == null ? 'Get Ideas' : 'Get More Ideas',
            gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(widget.isDark ? 0.1 : 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6366F1).withOpacity(0.15),
                  Color(0xFF8B5CF6).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Color(0xFF8B5CF6), size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.8),
                height: 1.5,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                        Color(0xFF6366F1),
                      ],
                      stops: [0.0, 0.33, 0.66, 1.0],
                      transform: GradientRotation(_shimmerController.value * 2 * math.pi),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDark ? Color(0xFF0A0E27) : Colors.white,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 48,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ).createShader(bounds),
              child: Text(
                'AI is thinking...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Creating something amazing',
              style: TextStyle(
                fontSize: 14,
                color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    debugPrint(error);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEF4444).withOpacity(0.15),
                    Color(0xFFF87171).withOpacity(0.15),
                  ],
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 10,
                  color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  height: 1.6,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
    
  }

  Widget _buildResultState(String text) {
    debugPrint(text);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(widget.isDark ? 0.1 : 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6366F1).withOpacity(0.15),
                        Color(0xFF8B5CF6).withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 6),
                      Text(
                        'Generated Content',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B5CF6),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                _buildActionButton(
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    _showCopiedNotification();
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: widget.isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1).withOpacity(0.15),
            Color(0xFF8B5CF6).withOpacity(0.15),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: CircleBorder(),
          child: Icon(icon, color: Color(0xFF8B5CF6), size: 18),
        ),
      ),
    );
  }

  Widget _buildInitialState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6366F1).withOpacity(0.08),
                    Color(0xFF8B5CF6).withOpacity(0.08),
                    Color(0xFFEC4899).withOpacity(0.08),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 56,
                color: Color(0xFF8B5CF6).withOpacity(0.6),
              ),
            ),
            SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ).createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.6),
                height: 1.6,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    final isDisabled = onPressed == null;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: isDisabled ? Colors.grey.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
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

class _ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  _ParticlesPainter({required this.animation, required this.isDark})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final progress = (animation.value + (i / 30)) % 1.0;
      final x = (i * 37) % size.width;
      final y = size.height * progress;
      final opacity = (1 - progress) * 0.25;

      paint.color = [
        Color(0xFF6366F1),
        Color(0xFF8B5CF6),
        Color(0xFFEC4899),
      ][i % 3].withOpacity(opacity);

      final double radius = 2 + (i % 3).toDouble();
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}