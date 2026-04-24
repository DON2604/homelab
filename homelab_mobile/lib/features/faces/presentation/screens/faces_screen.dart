import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/faces/domain/models/face_models.dart';
import 'package:homelab_mobile/features/faces/presentation/providers/faces_provider.dart';
import 'package:homelab_mobile/features/faces/presentation/screens/person_detail_screen.dart';

/// Main Faces screen — shows clustered face groups as premium "folder" cards.
/// Opened by tapping the coming.gif in the gallery app bar.
class FacesScreen extends ConsumerWidget {
  const FacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(personsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        displacement: 80,
        onRefresh: () async => ref.invalidate(personsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _FacesAppBar(onRefresh: () => ref.invalidate(personsProvider)),
            personsAsync.when(
              loading: () => const SliverFillRemaining(child: _LoadingState()),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(personsProvider),
                ),
              ),
              data: (persons) {
                if (persons.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
                }
                return _PersonGrid(persons: persons);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _FacesAppBar extends StatelessWidget {
  const _FacesAppBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 150,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh clusters',
          onPressed: onRefresh,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background.withAlpha(230),
                  AppTheme.background.withAlpha(120),
                ],
              ),
            ),
            child: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 10,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Powered',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.accent,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Faces and similarity',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Person Grid ───────────────────────────────────────────────────────────────

class _PersonGrid extends StatelessWidget {
  const _PersonGrid({required this.persons});

  final List<FaceCluster> persons;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _PersonFolderCard(person: persons[index]),
          childCount: persons.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
      ),
    );
  }
}

// ── Premium Folder Card ───────────────────────────────────────────────────────

class _PersonFolderCard extends ConsumerWidget {
  const _PersonFolderCard({required this.person});

  final FaceCluster person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(personImagesProvider(person.id));
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.push<void>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => PersonDetailScreen(person: person),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.surface, AppTheme.surfaceVariant],
          ),
          border: Border.all(
            color: AppTheme.outline.withOpacity(0.35),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail mosaic
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: imagesAsync.when(
                  loading: () => _ThumbnailPlaceholder(personId: person.id),
                  error: (_, __) => _ThumbnailPlaceholder(personId: person.id),
                  data: (images) => images.isEmpty
                      ? _ThumbnailPlaceholder(personId: person.id)
                      : _FaceMosaic(images: images),
                ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_rounded,
                        size: 12,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${person.faceCount} photo${person.faceCount == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.accent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Face Mosaic (up to 4 thumbnails) ─────────────────────────────────────────

class _FaceMosaic extends StatelessWidget {
  const _FaceMosaic({required this.images});

  final List<FaceImage> images;

  @override
  Widget build(BuildContext context) {
    final previews = images.take(4).toList();

    if (previews.length == 1) {
      return _ThumbImg(url: previews[0].thumbnailUrl);
    }

    if (previews.length == 2) {
      return Row(
        children: previews
            .map((img) => Expanded(child: _ThumbImg(url: img.thumbnailUrl)))
            .toList(),
      );
    }

    if (previews.length == 3) {
      return Row(
        children: [
          Expanded(child: _ThumbImg(url: previews[0].thumbnailUrl)),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _ThumbImg(url: previews[1].thumbnailUrl)),
                Expanded(child: _ThumbImg(url: previews[2].thumbnailUrl)),
              ],
            ),
          ),
        ],
      );
    }

    // 4 thumbnails in 2×2 grid
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _ThumbImg(url: previews[0].thumbnailUrl)),
              Expanded(child: _ThumbImg(url: previews[1].thumbnailUrl)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _ThumbImg(url: previews[2].thumbnailUrl)),
              Expanded(child: _ThumbImg(url: previews[3].thumbnailUrl)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThumbImg extends StatelessWidget {
  const _ThumbImg({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppTheme.surfaceVariant),
      errorWidget: (_, __, ___) => Container(
        color: AppTheme.surfaceVariant,
        child: Icon(
          Icons.face_outlined,
          size: 28,
          color: AppTheme.outline.withOpacity(0.6),
        ),
      ),
    );
  }
}

// ── Placeholder when no images loaded yet ─────────────────────────────────────

class _ThumbnailPlaceholder extends StatefulWidget {
  const _ThumbnailPlaceholder({required this.personId});

  final int personId;

  @override
  State<_ThumbnailPlaceholder> createState() => _ThumbnailPlaceholderState();
}

class _ThumbnailPlaceholderState extends State<_ThumbnailPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Derive a stable accent color per person
    final hue = (widget.personId * 67 % 360).toDouble();
    final baseColor = HSLColor.fromAHSL(1, hue, 0.4, 0.25).toColor();

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                baseColor.withOpacity(0.4 + _anim.value * 0.3),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.25 + _anim.value * 0.2),
            ),
          ),
        );
      },
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingFaceIcon(),
          const SizedBox(height: 20),
          Text(
            'Loading face clusters…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingFaceIcon extends StatefulWidget {
  @override
  State<_PulsingFaceIcon> createState() => _PulsingFaceIconState();
}

class _PulsingFaceIconState extends State<_PulsingFaceIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 0.9 + _ctrl.value * 0.15;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accent.withOpacity(0.3 + _ctrl.value * 0.3),
                  AppTheme.accent.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.face_retouching_natural_rounded,
              size: 36,
              color: AppTheme.accent,
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceVariant,
                border: Border.all(color: AppTheme.outline.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.face_outlined,
                size: 48,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Text('No Face Clusters Yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'The AI engine hasn\'t finished scanning your photos. '
              'Come back after the background worker has processed your library.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface.withOpacity(0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Could not connect',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
