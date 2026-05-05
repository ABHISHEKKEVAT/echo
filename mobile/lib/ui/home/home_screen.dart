import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/generated/l10n/app_localizations.dart';
import 'package:mobile/routing/routes.dart';
import 'package:mobile/ui/core/themes/app_spacing.dart';
import 'package:mobile/ui/core/widgets/app_avatar.dart';
import 'package:mobile/ui/core/widgets/app_bottom_nav_bar.dart';
import 'package:mobile/ui/core/widgets/app_sidebar_drawer.dart';
import 'package:mobile/ui/home/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const palette = _HomePalette();

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101526), Color(0xFF121A2F), Color(0xFF0E1324)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _AmbientGlow(),
              ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  final filtered = viewModel.filteredPosts;
                  final posts = filtered.isNotEmpty
                      ? filtered
                      : viewModel.posts;
                  final leadPost = posts.isNotEmpty ? posts.first : null;
                  return Column(
                    children: [
                      _HomeHeader(
                        palette: palette,
                        title: l10n.homeTitle,
                        leadPost: leadPost,
                      ),
                      _HomeCategoryTabs(
                        activeCategory: viewModel.activeCategory,
                        onSelected: viewModel.setCategory,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildBody(context, l10n, palette, posts),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentTab: AppBottomNavTab.home,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    _HomePalette palette,
    List<HomeFeedPost> posts,
  ) {
    switch (viewModel.state) {
      case HomeScreenState.loading:
        return Center(child: CircularProgressIndicator(color: palette.accent));
      case HomeScreenState.error:
        return Center(
          child: _GlassCard(
            palette: palette,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: viewModel.loadFeed,
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            ),
          ),
        );
      case HomeScreenState.empty:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          children: [
            _CampusDiscoverCard(
              palette: palette,
              activeCategory: viewModel.activeCategory,
              postCount: 0,
            ),
            const SizedBox(height: 10),
            _GlassCard(
              palette: palette,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.emptyMessage,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        );
      case HomeScreenState.data:
        return RefreshIndicator(
          color: palette.accent,
          backgroundColor: palette.surface,
          onRefresh: viewModel.loadFeed,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            children: [
              _CampusDiscoverCard(
                palette: palette,
                activeCategory: viewModel.activeCategory,
                postCount: posts.length,
              ),
              const SizedBox(height: 10),
              if (posts.isNotEmpty)
                ...posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HomePostCard(
                      post: post,
                      palette: palette,
                      onToggleLike: () => viewModel.toggleLike(post.id),
                      onLoadComments: () => viewModel.loadComments(post.id),
                      onAddComment: (text) =>
                          viewModel.addComment(post.id, text),
                      onShare: () => _sharePost(context, post),
                    ),
                  ),
                )
              else
                _GlassCard(
                  palette: palette,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No posts yet in this lane.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              _TodayFeedCard(palette: palette),
              const SizedBox(height: 10),
              const _TalentSpotlightCard(),
            ],
          ),
        );
    }
  }

  void _sharePost(BuildContext context, HomeFeedPost post) {
    final shareText =
        post.spotifyUrl ?? post.text ?? 'Check this post from ${post.userName}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post link copied. Share it anywhere.')),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.palette,
    required this.title,
    required this.leadPost,
  });

  final _HomePalette palette;
  final String title;
  final HomeFeedPost? leadPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: palette.surface.withValues(alpha: 0.8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => showAppSidebar(context),
              ),
              Expanded(
                child: Text(
                  '$title Feed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                onPressed: () => context.push(Routes.notifications),
              ),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () => context.push(Routes.search),
              ),
            ],
          ),
          Container(
            height: 2.2,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [Color(0xFF3A6DFF), Color(0xFF8A63FF)],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Feed',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (leadPost != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  AppAvatar(
                    radius: 16,
                    imageProvider: leadPost!.userAvatarUrl != null
                        ? NetworkImage(leadPost!.userAvatarUrl!)
                        : null,
                    backgroundColor: const Color(0xFF2B3550),
                    fallbackText: leadPost!.userInitials,
                    fallbackTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Active now',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeCategoryTabs extends StatelessWidget {
  const _HomeCategoryTabs({
    required this.activeCategory,
    required this.onSelected,
  });

  final HomeFeedCategory activeCategory;
  final ValueChanged<HomeFeedCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: HomeFeedCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = HomeFeedCategory.values[index];
          return _CategoryChip(
            label: _categoryLabel(category),
            selected: category == activeCategory,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const [Color(0xFF6A47FF), Color(0xFF4D2ACA)]
        : const [Color(0xFF242A3D), Color(0xFF1D2333)];

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: bg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CampusDiscoverCard extends StatelessWidget {
  const _CampusDiscoverCard({
    required this.palette,
    required this.activeCategory,
    required this.postCount,
  });

  final _HomePalette palette;
  final HomeFeedCategory activeCategory;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campus Discover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22 / 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Friends',
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _StatPill(label: '$postCount Posts', icon: Icons.forum_rounded),
                _StatPill(label: '4 Music', icon: Icons.music_note_rounded),
                _StatPill(label: '3 People', icon: Icons.group_rounded),
                _StatPill(label: _categoryLabel(activeCategory)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 26,
              child: CustomPaint(
                painter: _WaveLinePainter(color: const Color(0xFF8468FF)),
                size: const Size(double.infinity, 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePostCard extends StatelessWidget {
  const _HomePostCard({
    required this.post,
    required this.palette,
    required this.onToggleLike,
    required this.onLoadComments,
    required this.onAddComment,
    required this.onShare,
  });

  final HomeFeedPost post;
  final _HomePalette palette;
  final Future<void> Function() onToggleLike;
  final Future<List<HomeFeedComment>> Function() onLoadComments;
  final Future<HomeFeedComment?> Function(String text) onAddComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  radius: 17,
                  imageProvider: post.userAvatarUrl != null
                      ? NetworkImage(post.userAvatarUrl!)
                      : null,
                  backgroundColor: _seedColor(post.userId, shift: 0),
                  fallbackText: post.userInitials,
                  fallbackTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${post.userId}'),
                        child: Text(
                          post.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        post.userHandle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onShare,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            if (post.text != null && post.text!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.text!,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2233),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      icon: Icons.favorite_rounded,
                      label: 'Hearts',
                      value: post.likeCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _MetricBox(
                      icon: Icons.music_note_rounded,
                      label: 'Music',
                      value: post.spotifyUrl != null ? '1' : '0',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _MetricBox(
                      icon: Icons.flash_on_rounded,
                      label: 'Engagement',
                      value: post.commentCount.toString(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _CounterAction(
                  icon: post.currentUserLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  value: post.likeCount,
                  onTap: () => onToggleLike(),
                  active: post.currentUserLiked,
                ),
                const SizedBox(width: 14),
                _CounterAction(
                  icon: Icons.mode_comment_outlined,
                  value: post.commentCount,
                  onTap: () => _openCommentsSheet(context),
                ),
                const Spacer(),
                if (post.spotifyUrl != null)
                  TextButton(onPressed: onShare, child: const Text('Spotify')),
                IconButton(
                  tooltip: 'Share',
                  onPressed: onShare,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCommentsSheet(BuildContext context) async {
    final initialComments = await onLoadComments();
    if (!context.mounted) return;
    final controller = TextEditingController();
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF171D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final comments = [...initialComments];

        void submitComment(String rawValue) {
          final text = rawValue.trim();
          if (text.isEmpty) return;
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop(text);
        }

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 / 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (comments.isEmpty)
                const Text(
                  'No comments yet. Be the first one.',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Text.rich(
                        TextSpan(
                          style: const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: '${comment.authorName}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: comment.text),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write a comment',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF232B3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => submitComment(controller.text),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: submitComment,
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (submitted == null) return;
    await onAddComment(submitted);
  }
}

class _TodayFeedCard extends StatelessWidget {
  const _TodayFeedCard({required this.palette});

  final _HomePalette palette;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Today in your feed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'A quick social pulse for your current filter',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _MiniSoundTile(title: 'Taste visuals')),
                SizedBox(width: 8),
                Expanded(child: _MiniSoundTile(title: 'Recommendations')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSoundTile extends StatelessWidget {
  const _MiniSoundTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF212A40),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomPaint(
              painter: _WaveLinePainter(color: const Color(0xFF8A63FF)),
              size: const Size(double.infinity, 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TalentSpotlightCard extends StatelessWidget {
  const _TalentSpotlightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171F31).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'New Talent Spotlight',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22 / 1.2,
            ),
          ),
          SizedBox(height: 10),
          _SpotlightRow(
            name: 'Marcus J.',
            subtitle: 'Digital Sculptor',
            seed: 'marcus',
          ),
          SizedBox(height: 8),
          _SpotlightRow(
            name: 'Kiko Lin',
            subtitle: 'Interactive Artist',
            seed: 'kiko',
          ),
        ],
      ),
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({
    required this.name,
    required this.subtitle,
    required this.seed,
  });

  final String name;
  final String subtitle;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: _seedColor(seed, shift: 5),
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                TextSpan(
                  text: '$name ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: '($subtitle)'),
              ],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: const BorderSide(color: Color(0xFF6A47FF)),
          ),
          child: const Text('Follow'),
        ),
      ],
    );
  }
}

class _CounterAction extends StatelessWidget {
  const _CounterAction({
    required this.icon,
    required this.value,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final int value;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFFF6A7E) : Colors.white70;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF11192A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF2E3550),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.palette, required this.child});

  final _HomePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface.withValues(alpha: 0.95),
            const Color(0xFF1B2236).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7052FF).withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: -90,
            child: _GlowCircle(
              diameter: 280,
              color: const Color(0xFF3D5CFF).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            right: -100,
            bottom: 160,
            child: _GlowCircle(
              diameter: 260,
              color: const Color(0xFFFF6B4A).withValues(alpha: 0.09),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _WaveLinePainter extends CustomPainter {
  _WaveLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final baseline = size.height * 0.55;
    path.moveTo(0, baseline);

    for (double x = 0; x <= size.width; x += 4) {
      final y = baseline + math.sin(x * 0.09) * 2.6;
      path.lineTo(x, y);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HomePalette {
  const _HomePalette();

  final Color background = const Color(0xFF0E1220);
  final Color surface = const Color(0xFF141B2C);
  final Color accent = const Color(0xFF6A47FF);
}

Color _seedColor(String seed, {required int shift}) {
  final hash = seed.hashCode;
  final r = 90 + ((hash >> (shift + 2)) & 0x4F);
  final g = 70 + ((hash >> (shift + 5)) & 0x5F);
  final b = 100 + ((hash >> (shift + 8)) & 0x4F);
  return Color.fromARGB(255, r, g, b);
}

extension on HomeFeedPost {
  String get userInitials => userName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

String _categoryLabel(HomeFeedCategory category) {
  return switch (category) {
    HomeFeedCategory.ibsFirstYear => 'IBS 1st Year',
    HomeFeedCategory.ibsCorporateFinance => 'IBS Corporate Finance',
    HomeFeedCategory.budapest => 'Budapest',
    HomeFeedCategory.friends => 'Friends',
  };
}
