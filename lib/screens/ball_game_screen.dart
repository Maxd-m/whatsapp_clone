import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase/chat_service.dart';

class BallGameScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const BallGameScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<BallGameScreen> createState() => _BallGameScreenState();
}

class _BallGameScreenState extends State<BallGameScreen> {
  final ChatService _chatService = ChatService();
  
  double ballY = 0; 
  double velocity = 0; 
  final double gravity = 0.005; 
  final double jumpStrength = 0.1;

  int score = 0;
  bool gameHasStarted = false;
  bool isGameOver = false;
  Timer? timer;

void startGame() {
    gameHasStarted = true;
    isGameOver = false;
    score = 0;
    ballY = 0; 
    velocity = 0;

    timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        velocity += gravity;
        ballY += velocity;

        if (ballY >= 1.0) {
          timer.cancel();
          isGameOver = true;
          
          _chatService.updateGameRecord(widget.chatId, widget.currentUserId, score);

          ballY = 0; 
          velocity = 0; 
        }
      });
    });
  }

  void jump() {
    if (!gameHasStarted || isGameOver) return;
    setState(() {
      velocity = -jumpStrength; 
      score++; 
    });
  }

  @override
  void dispose() {
    timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text('No dejes que caiga!'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () {
          if (isGameOver) {
            startGame();
            jump(); 
          } else if (!gameHasStarted) {
            startGame();
            jump();
          } else {
            jump();
          }
        },
        child: Stack(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _chatService.getChatRecordStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                
                var data = snapshot.data!.data() as Map<String, dynamic>;
                int highScore = data.containsKey('highScore') ? data['highScore'] : 0;
                String holderId = data.containsKey('highScoreHolderId') ? data['highScoreHolderId'] : 'Nadie';

                String displayHolder = holderId == widget.currentUserId ? 'Tú' : 'Otro participante';
                if (highScore == 0) displayHolder = 'Nadie';

                return Align(
                  alignment: const Alignment(0, -0.8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Récord del Chat: $highScore',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Por: $displayHolder',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),

            Align(
              alignment: const Alignment(0, -0.4),
              child: Text(
                score.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
              ),
            ),

            if (!gameHasStarted)
              const Align(
                alignment: Alignment(0, 0.2),
                child: Text('Toca para empezar', style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            if (isGameOver)
              const Align(
                alignment: Alignment(0, 0.2),
                child: Text('Cayó! Toca para intentar de nuevo', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              ),

            AnimatedContainer(
              alignment: Alignment(0, ballY),
              duration: const Duration(milliseconds: 0),
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.orange, blurRadius: 10)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}