import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
  });

  @override
  // 🚨 CORRECCIÓN 1: Devolver la clase con el nombre público
  VideoPlayerItemState createState() => VideoPlayerItemState();
}

// 🚨 CORRECCIÓN 1: Renombrar la clase State para que sea pública (eliminar el _)
class VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController videoPlayerController;

  @override
  void initState() {
    super.initState();
    
    // 🚨 CORRECCIÓN 2: Usar VideoPlayerController.networkUrl para evitar la deprecación
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((value) {
        // Debes verificar si el widget está montado antes de llamar a play/setVolume
        // aunque en initState es generalmente seguro, es buena práctica:
        if (mounted) { 
          videoPlayerController.play();
          videoPlayerController.setVolume(1);
        }
      });
  }

  @override
  void dispose() {
    videoPlayerController.dispose(); // Asegurarse de disponer primero
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      // Asegúrate de que el controlador esté inicializado antes de mostrar VideoPlayer
      child: videoPlayerController.value.isInitialized
          ? VideoPlayer(videoPlayerController)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}