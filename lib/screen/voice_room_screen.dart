Future<void> _initAgoraAndJoin() async {
    await [Permission.microphone].request();

    try {
      final tokenUrl = Uri.parse(
        '${UserService.serverUrl}/api/agora/token?channelName=${widget.channelId}&uid=${_userService.userId}',
      );
      final res = await http.get(tokenUrl);
      final resData = jsonDecode(res.body);

      final String appId = resData['appId'] ?? '';
      final String token = resData['token'] ?? '';

      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() => _isJoined = true);
            if (widget.isHost) {
              _takeSeat(0);
            }
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            setState(() {});
          },
        ),
      );

      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await _engine.enableAudio();

      // High Quality Audio Configurations
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      await _engine.adjustRecordingSignalVolume(100);
      await _engine.adjustPlaybackSignalVolume(100);

      await _engine.joinChannel(
        token: token,
        channelId: widget.channelId,
        uid: int.tryParse(_userService.userId) ?? 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: false,
          enableAudioRecordingOrPlayout: true,
        ),
      );
    } catch (e) {
      debugPrint('Agora initialization error: $e');
    }
  }
