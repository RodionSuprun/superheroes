import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/model/alignment_info.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';

class SuperheroCard extends StatelessWidget {
  final SuperheroInfo superheroInfo;
  final VoidCallback onTap;

  const SuperheroCard(
      {Key? key, required this.superheroInfo, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: SuperheroesColors.indigo,
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            _AvatarWidget(superheroInfo: superheroInfo),
            const SizedBox(
              width: 12,
            ),
            NameAndRealNameWidget(superheroInfo: superheroInfo),
            if (superheroInfo.alignmentInfo != null)
              AlignmentWidget(alignmentInfo: superheroInfo.alignmentInfo!),
          ],
        ),
      ),
    );
  }
}

class AlignmentWidget extends StatelessWidget {
  final AlignmentInfo alignmentInfo;

  const AlignmentWidget({Key? key, required this.alignmentInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        color: alignmentInfo.color,
        child: Text(
          alignmentInfo.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class NameAndRealNameWidget extends StatelessWidget {
  const NameAndRealNameWidget({
    Key? key,
    required this.superheroInfo,
  }) : super(key: key);

  final SuperheroInfo superheroInfo;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            superheroInfo.name.toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(
            superheroInfo.realName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
          )
        ],
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    Key? key,
    required this.superheroInfo,
  }) : super(key: key);

  final SuperheroInfo superheroInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: 70,
      color: Colors.white24,
      child: CachedNetworkImage(
        imageUrl: superheroInfo.imageUrl,
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        progressIndicatorBuilder: (context, url, progress) {
          return Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: SuperheroesColors.blue,
                value: progress.progress,
              ),
            ),
          );
        },
        errorWidget: (context, url, error) {
          return Center(
            child: Image.asset(
              SuperheroesImages.unknownImage,
              height: 62,
              width: 20,
            ),
          );
        },
      ),
    );
  }
}
