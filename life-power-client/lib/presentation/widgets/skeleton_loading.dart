import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final Widget? skeleton;

  const SkeletonLoading({
    Key? key,
    required this.isLoading,
    required this.child,
    this.skeleton,
  }) : super(key: key);

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    if (widget.skeleton != null) {
      return widget.skeleton!;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFe0e0e0),
                Color(0xFFf0f0f0),
                Color(0xFFe0e0e0),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    Key? key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFe8e8e8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildSkeletonRing(),
          const SizedBox(height: 48),
          _buildSkeletonWatchers(),
          const SizedBox(height: 32),
          _buildSkeletonBentoGrid(),
          const SizedBox(height: 32),
          _buildSkeletonHistory(),
          const SizedBox(height: 32),
          _buildSkeletonButton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSkeletonRing() {
    return Container(
      width: 288,
      height: 288,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFe8e8e8).withOpacity(0.5),
            const Color(0xFFf5f5f5).withOpacity(0.5),
          ],
        ),
      ),
      child: const Center(
        child: _SkeletonPulse(),
      ),
    );
  }

  Widget _buildSkeletonWatchers() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFe8e8e8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFe8e8e8),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBentoGrid() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFe8e8e8),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFe8e8e8),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFe8e8e8),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFe8e8e8),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFe8e8e8),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFe8e8e8),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFe8e8e8),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFe8e8e8),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  const _SkeletonPulse();

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFd0d0d0),
            ),
            child: const Center(
              child: Text(
                '88%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
