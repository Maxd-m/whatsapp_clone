import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/chat_model.dart'; 
import '../firebase/chat_service.dart';
import '../utils/supabase_storage_service.dart';
import 'ball_game_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatTitle,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  
  bool _isUploading = false;

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _chatService.sendMessage(
      widget.chatId,
      widget.currentUserId,
      _messageController.text.trim(),
      'text',
    );

    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() { _isUploading = true; });

      File file = File(image.path);
      String? imageUrl = await _storageService.uploadFile(file, widget.currentUserId);

      if (imageUrl != null && mounted) {
        _chatService.sendMessage(
          widget.chatId,
          widget.currentUserId,
          imageUrl,
          'image',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la imagen')),
        );
      }

      setState(() { _isUploading = false; });
    }
  }

  Future<void> _sendVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() { _isUploading = true; });

      File file = File(video.path);
      String? videoUrl = await _storageService.uploadFile(file, widget.currentUserId);

      if (videoUrl != null && mounted) {
        _chatService.sendMessage(
          widget.chatId,
          widget.currentUserId,
          videoUrl,
          'video',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el video')),
        );
      }

      setState(() { _isUploading = false; });
    }
  }

  Future<void> _sendDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() { _isUploading = true; });

      File file = File(result.files.single.path!);
      String fileName = result.files.single.name; 

      String? fileUrl = await _storageService.uploadFile(file, widget.currentUserId);

      if (fileUrl != null && mounted) {
        String messageData = "$fileName||$fileUrl";

        _chatService.sendMessage(
          widget.chatId,
          widget.currentUserId,
          messageData,
          'document', 
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el documento')),
        );
      }

      setState(() { _isUploading = false; });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.image, color: Colors.white),
                ),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _sendImage();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.pink,
                  child: Icon(Icons.videocam, color: Colors.white),
                ),
                title: const Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  _sendVideo();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.insert_drive_file, color: Colors.white),
                ),
                title: const Text('Documento'),
                onTap: () {
                  Navigator.pop(context);
                  _sendDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNewDay(Message currentMessage, Message previousMessage) {
    final current = currentMessage.createdAt;
    final previous = previousMessage.createdAt;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  String _getDateSeparatorText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Hoy';
    if (messageDate == yesterday) return 'Ayer';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        backgroundColor: const Color(0xFF128C7E),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            tooltip: 'Iniciar Videollamada',
            onPressed: () async {
              String realName = await _chatService.getUserNameById(widget.currentUserId);

              if (!context.mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(
                    chatId: widget.chatId, 
                    currentUserId: widget.currentUserId,
                    currentUserName: realName,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sports_esports), 
            tooltip: 'Minijuego',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BallGameScreen(
                    chatId: widget.chatId,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar mensajes'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, 
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    bool showDateSeparator = false;
                    if (index == messages.length - 1) {
                      showDateSeparator = true; 
                    } else {
                      final previousMessage = messages[index + 1];
                      showDateSeparator = _isNewDay(message, previousMessage);
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getDateSeparatorText(message.createdAt),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ),
                        _MessageBubble(message: message, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(color: Color(0xFF128C7E)),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _isUploading ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                  controller: _messageController,
                  
                  contentInsertionConfiguration: ContentInsertionConfiguration(
                    allowedMimeTypes: const <String>['image/gif', 'image/png', 'image/jpeg'],
                    onContentInserted: (KeyboardInsertedContent content) async {
                      final bytes = content.data; 
                      
                      if (bytes != null) {
                        setState(() { _isUploading = true; });
                        
                        String extension = '.gif';
                        if (content.mimeType != null && content.mimeType!.contains('/')) {
                          extension = '.${content.mimeType!.split('/').last}';
                        }

                        String? imageUrl = await _storageService.uploadBytes(bytes, widget.currentUserId, extension);

                        if (imageUrl != null && mounted) {
                          _chatService.sendMessage(
                            widget.chatId,
                            widget.currentUserId,
                            imageUrl,
                            'image', 
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al enviar el GIF del teclado')),
                          );
                        }

                        setState(() { _isUploading = false; });
                      }
                    },
                  ),
                  
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF128C7E),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isUploading ? null : _sendMessage,
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


class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isImage = message.type == 'image';
    final isVideo = message.type == 'video';
    final isDocument = message.type == 'document'; 

    String docName = "Documento";
    String docUrl = "";
    if (isDocument) {
      var parts = message.text.split('||');
      if (parts.length == 2) {
        docName = parts[0];
        docUrl = parts[1];
      } else {
        docUrl = message.text; 
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: (isImage || isVideo) 
            ? const EdgeInsets.all(4) 
            : const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.text,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 150,
                      width: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              )
            else if (isVideo)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 250,
                  width: 200,
                  child: VideoPlayerItem(videoUrl: message.text),
                ),
              )
            else if (isDocument)
              GestureDetector(
               onTap: () async {
                  final Uri url = Uri.parse(docUrl.trim()); 
                  
                  try {
                    bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                    
                    if (!launched && context.mounted) {
                      throw Exception("El sistema rechazó abrir el enlace");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo abrir el documento: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          docName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(message.text, style: const TextStyle(fontSize: 16)),
            
            const SizedBox(height: 4),
            Text(
              "${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({super.key, required this.videoUrl});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        IconButton(
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 50,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
        ),
      ],
    );
  }
}