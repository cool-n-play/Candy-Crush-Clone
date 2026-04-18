import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/level_end_state.dart';

/// Donor-style panel ([GameOverComponent]): one box, title depends on outcome.
class LevelEndOverlay extends StatelessWidget {
  const LevelEndOverlay({
    super.key,
    required this.state,
    required this.onRestart,
    required this.onNext,
  });

  final LevelEndState state;
  final VoidCallback onRestart;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (state == LevelEndState.none) {
      return const SizedBox.shrink();
    }
    final title = state == LevelEndState.won ? 'You Won!' : 'Game Over';
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ModalBarrier(
            color: Colors.black.withOpacity(0.45),
            dismissible: false,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8D6E63), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      key: const ValueKey('level_end_title'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pacifico(
                        fontSize: 44,
                        color: const Color(0xFFFF6F00),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _CandyPillButton(
                      key: const Key('level_end_restart'),
                      label: 'Restart',
                      onPressed: onRestart,
                    ),
                    const SizedBox(height: 14),
                    _CandyPillButton(
                      key: const Key('level_end_next'),
                      label: 'Next',
                      onPressed: onNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandyPillButton extends StatelessWidget {
  const _CandyPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF80AB), Color(0xFFFF4081)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF6F00),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
