import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'support_audio.dart';
import 'support_text.dart';

/// One active player across the chat, including the unsent preview.
class SupportAudioPlayer extends StatefulWidget {
  const SupportAudioPlayer(
      {super.key,
      required this.load,
      this.onPrimary = false,
      this.playerFactory});

  final Future<SupportAudio> Function() load;
  final bool onPrimary;
  final AudioPlayer Function()? playerFactory;

  static final active = ValueNotifier<Object?>(null);

  @override
  State<SupportAudioPlayer> createState() => _SupportAudioPlayerState();
}

class _SupportAudioPlayerState extends State<SupportAudioPlayer>
    with WidgetsBindingObserver {
  AudioPlayer? _player;
  SupportAudio? _audio;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _loading = false;
  bool _playing = false;
  bool _error = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupportAudioPlayer.active.addListener(_activeChanged);
  }

  void _activeChanged() {
    if (SupportAudioPlayer.active.value != this) _pause();
  }

  void _pause() {
    if (_playing) {
      unawaited(_player?.pause().catchError((Object _) {}));
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (SupportAudioPlayer.active.value == this) {
        SupportAudioPlayer.active.value = null;
      }
      _pause();
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_playing) {
      _pause();
      return;
    }
    SupportAudioPlayer.active.value = this;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      _audio ??= await widget.load();
      if (!mounted || SupportAudioPlayer.active.value != this) return;
      if (_player == null) {
        final player = _player = widget.playerFactory?.call() ?? AudioPlayer();
        _subscriptions.add(player.onPositionChanged.listen((position) {
          if (mounted) setState(() => _position = position);
        }));
        _subscriptions.add(player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
          }
        }));
        _subscriptions
            .add(player.eventStream.listen((_) {}, onError: (Object _) {
          if (mounted) {
            setState(() {
              _playing = false;
              _error = true;
              _loading = false;
            });
          }
        }));
      }
      await _player!.play(BytesSource(_audio!.bytes, mimeType: 'audio/wav'),
          position: _position);
      if (!mounted || SupportAudioPlayer.active.value != this) {
        await _player?.pause();
        return;
      }
      setState(() => _playing = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _playing = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SupportAudioPlayer.active.removeListener(_activeChanged);
    if (SupportAudioPlayer.active.value == this) {
      SupportAudioPlayer.active.value = null;
    }
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player?.dispose().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final tokens = theme.designToken;
    final color = widget.onPrimary ? theme.info : theme.primaryText;
    final duration = Duration(milliseconds: _audio?.durationMs ?? 0);
    final label = supportText(
        context,
        _error
            ? 'retry'
            : _playing
                ? 'pauseAudio'
                : 'playAudio');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (_loading)
            SizedBox(
                width: 48,
                height: 48,
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacing.sm),
                  child:
                      CircularProgressIndicator(color: color, strokeWidth: 2),
                ))
          else
            Tooltip(
                excludeFromSemantics: true,
                message: label,
                child: Semantics(
                  button: true,
                  label: label,
                  child: FlutterFlowIconButton(
                    key: const ValueKey('support-audio-play'),
                    buttonSize: 48,
                    borderRadius: tokens.radius.full,
                    icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: color),
                    onPressed: _toggle,
                  ),
                )),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(supportText(context, 'audioMessage'),
                    style: theme.bodyMedium.override(color: color)),
                SizedBox(height: tokens.spacing.xs),
                LinearProgressIndicator(
                  value: duration.inMilliseconds == 0
                      ? 0
                      : (_position.inMilliseconds / duration.inMilliseconds)
                          .clamp(0, 1),
                  color: color,
                  backgroundColor: color.withValues(alpha: .16),
                ),
                if (_audio != null)
                  Text(
                      '${supportAudioTime(_position)} / ${supportAudioTime(duration)}',
                      style: theme.labelSmall.override(color: color)),
              ])),
        ]),
        if (_error)
          Text(supportText(context, 'audioLoadError'),
              style: theme.bodySmall.override(color: color)),
      ]),
    );
  }
}
