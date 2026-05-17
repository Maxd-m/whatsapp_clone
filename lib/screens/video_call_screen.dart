import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VideoCallScreen extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String currentUserName;

  const VideoCallScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {

    final int appId = int.parse(
      dotenv.env['APPID_ZEGOCLOUD']!,
    );

    final String appSign =
        dotenv.env['APPSIGN_ZEGOCLOUD']!;

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: appId,
        appSign: appSign,
        userID: currentUserId,
        userName: currentUserName,
        callID: chatId,

        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
      ),
    );
  }
}