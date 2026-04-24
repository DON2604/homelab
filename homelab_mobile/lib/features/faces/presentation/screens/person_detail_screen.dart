import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/faces/domain/models/face_models.dart';
import 'package:homelab_mobile/features/faces/presentation/providers/faces_provider.dart';

/// Shows all photos containing a specific face cluster, with a rename option.
class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.person});

  final FaceCluster person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(personImagesProvider(person.id));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _PersonAppBar(person: person, ref: ref),
          imagesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _ErrorState(message: e.toString()),
            ),
            data: (images) => images.isEmpty
                ? const SliverFillRemaining(child: _EmptyState())
                : _ImageGrid(images: images),
          ),
        ],
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _PersonAppBar extends StatelessWidget {
  const _PersonAppBar({required this.person, required this.ref});

  final FaceCluster person;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Rename',
          onPressed: () => _showRenameDialog(context),
        ),
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
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  Text(
                    '${person.faceCount} photo${person.faceCount == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: person.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename Person', style: Theme.of(ctx).textTheme.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: Theme.of(ctx).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter name...',
            hintStyle: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurface.withOpacity(0.4),
                ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.outline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(renamePersonProvider.notifier).rename(person.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Image grid ────────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images});

  final List<FaceImage> images;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ImageTile(image: images[index]),
          childCount: images.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image});

  final FaceImage image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullImage(context),
      child: Hero(
        tag: 'face_img_${image.filePath}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: image.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppTheme.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.surfaceVariant,
              child: const Icon(Icons.broken_image_outlined, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageView(image: image),
      ),
    );
  }
}

// ── Full image view ───────────────────────────────────────────────────────────

class _FullImageView extends StatelessWidget {
  const _FullImageView({required this.image});

  final FaceImage image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Hero(
          tag: 'face_img_${image.filePath}',
          child: CachedNetworkImage(
            imageUrl: image.fullUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

// ── Empty / error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.face_outlined, size: 64, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text('No photos found',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text('Error loading photos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurface.withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
