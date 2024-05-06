// // Copyright 2022 Google LLC

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlayerWidget extends StatefulWidget {
  final String url;
  final PlayerMode mode;
  final BuildContext context;

  const PlayerWidget({
    Key? key,
    required this.url,
    this.mode = PlayerMode.mediaPlayer,
    required this.context,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  static const skipIntervalInSec = 15;

  late AudioPlayer _audioPlayer;

  Duration _duration = const Duration();
  Duration _position = const Duration();

  PlayerState _playerState = PlayerState.stopped;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<PlayerState> _playerStateSubscription;

  String get _durationText => _durationToString(_duration);
  String get _positionText => _durationToString(_position);

  late Slider _slider;
  double _sliderPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _playerStateSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _slider = Slider(
      onChanged: _onSliderChangeHandler,
      value: _sliderPosition,
      divisions: 100,
      activeColor: Colors.purple.shade400,
      inactiveColor: Colors.purple.shade100,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _positionText,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: _slider,
                  ),
                  _duration.inSeconds == 0
                      ? getLocalFileDuration()
                      : Text(_durationText,
                        style: const TextStyle(fontSize: 18.0))
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('rewind_button'),
                    onPressed: _rewind,
                    iconSize: 48.0,
                    icon: const Icon(Icons.fast_rewind),
                    color: Colors.purple.shade400,
                  ),
                  IconButton(
                    key: const Key('play_button'),
                    onPressed:
                    _playerState == PlayerState.playing ? _pause : _play,
                    iconSize: 48.0,
                    icon: _playerState == PlayerState.playing
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                    color: Colors.purple.shade400,
                  ),
                  IconButton(
                    key: const Key('fastforward_button'),
                    onPressed: _forward,
                    iconSize: 48.0,
                    icon: const Icon(Icons.fast_forward),
                    color: Colors.purple.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSliderChangeHandler(double v) {
    if (kIsWeb && (v >= 1 || v == 0)) {
      // Avoid a bug in web player where extra tap gesture is bound.
      return;
    }
    _updateSlider(v);
  }

  void _updateSlider(double v) {
    _sliderPosition = v;
    _setPlaybackPositionWithSlider();

    // Avoid a bug in web where position is set to zero on pause.
    // Has to happen after playback position is set.
    if (kIsWeb && _playerState == PlayerState.paused) {
      _audioPlayer.pause();
    }
  }

  void _setPlaybackPositionWithSlider() {
    final position = _sliderPosition * _duration.inMilliseconds;
    _position = Duration(milliseconds: position.round());
    _seek(_position);
  }

  Future<Future<Duration?>> _getDuration() async {
    await _audioPlayer.setSourceUrl(widget.url);
    return _audioPlayer.getDuration();
  }

  FutureBuilder/*<int>*/ getLocalFileDuration() {
    return FutureBuilder/*<int>*/(
      future: _getDuration(),
      initialData: 0,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return const Text('...');
          case ConnectionState.done:
            if (snapshot.hasError) {
              if (kDebugMode) {
                print('Error: ${snapshot.error}');
              }
            } else if (snapshot.data != null) {
              _duration = Duration(milliseconds: snapshot.data!);
              return Text(_durationToString(_duration),
                  style: const TextStyle(fontSize: 18.0));
            }
            return const Text('...');
        }
      },
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(0.005);

    _durationSubscription =
        _audioPlayer.onDurationChanged.listen((duration) {
          setState(() => _duration = duration);
        });

    _positionSubscription =
        _audioPlayer.onPositionChanged.listen((p) {
          setState(() {
            _position = p;
            _setSliderWithPlaybackPosition();
          });
        });

    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
          setState(() => _playerState = state);
        });
  }

  Future<int> _play() async {
    await _audioPlayer.play(widget.url as Source);
    return 1;
  }

  Future<int> _pause() async {
    await _audioPlayer.pause();
    return 1;
  }

  Future<int> _seek(Duration _tempPosition) async {
    await _audioPlayer.seek(_tempPosition);
    return 1;
  }

  Future<int> _forward() async {
    return _updatePositionAndSlider(Duration(
        seconds:
        min(_duration.inSeconds, _position.inSeconds + skipIntervalInSec)));
  }

  Future<int> _rewind() async {
    return _updatePositionAndSlider(
        Duration(seconds: max(0, _position.inSeconds - skipIntervalInSec)));
  }

  Future<int> _updatePositionAndSlider(Duration tempPosition) async {
    await _audioPlayer.seek(tempPosition);
    return 1;
  }

  void _setSliderWithPlaybackPosition() {
    final position = _position.inSeconds / _duration.inSeconds;
    _sliderPosition = position.isNaN ? 0 : position;
  }

  String _durationToString(Duration? duration) {
    String twoDigits(int? n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration?.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration?.inSeconds.remainder(60));
    if (duration?.inHours == 0) {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
    return '${twoDigits(duration?.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
