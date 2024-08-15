import 'package:flutter/material.dart';
import 'package:getx_demo1/app/widgets/image_slider.dart';

class ImageSliderPage extends StatelessWidget {
  const ImageSliderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.hardEdge, // 确保启用裁剪
                child: Container(
                  height: 200,
                  color: Colors.green,
                  child: const ImageSlider(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Undresser.ai is the best choice for exploring your fantasies. The remarkable realism Undress AI offers is unmatched. The NSFW AI generator undresses photos that look almost identical to the original, capturing every curve and detail with stunning accuracy. Choose outfit, dressing style, body type. There are various exciting undress AI generator modes like Lingerie, Bikini, Cum, Bondage, Bunny Suits and more.',
              style: TextStyle(
                color: Color(0xFF4D4D4D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 44),
        ],
      ),
    );
  }
}
