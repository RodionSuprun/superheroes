import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/superhero_bloc.dart';
import 'package:superheroes/model/biography.dart';
import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/resources/superhero_icons.dart';
import 'package:superheroes/resources/superheroes_images.dart';

import '../model/alignment_info.dart';
import '../model/superhero.dart';
import '../resources/superheroes_colors.dart';
import 'package:http/http.dart' as http;

import '../widgets/info_with_button.dart';

class SuperheroPage extends StatefulWidget {
  final http.Client? client;
  final String id;

  const SuperheroPage({Key? key, this.client, required this.id})
      : super(key: key);

  @override
  State<SuperheroPage> createState() => _SuperheroPageState();
}

class _SuperheroPageState extends State<SuperheroPage> {
  late SuperheroBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = SuperheroBloc(client: widget.client, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: const Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SuperheroPageStateWidget(),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class SuperheroPageStateWidget extends StatelessWidget {
  const SuperheroPageStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SuperheroBloc bloc =
        Provider.of<SuperheroBloc>(context, listen: false);

    return StreamBuilder<SuperheroPageState>(
      stream: bloc.observeSuperheroPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        } else {
          final SuperheroPageState state = snapshot.data!;
          switch (state) {
            case SuperheroPageState.loading:
              return const LoadingWidget();
            case SuperheroPageState.loaded:
              return const SuperheroContentPage();
            case SuperheroPageState.error:
              return const ErrorWidget();
            default:
              return const SizedBox.shrink();
          }
        }
      },
    );
  }
}

class SuperheroContentPage extends StatelessWidget {
  const SuperheroContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SuperheroBloc bloc =
        Provider.of<SuperheroBloc>(context, listen: false);

    return StreamBuilder<Superhero>(
        stream: bloc.observeSuperhero(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final superhero = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SuperheroAppBar(superhero: superhero),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    if (superhero.powerstats.isNotNull())
                      PowerStatsWidget(powerstats: superhero.powerstats),
                    BiographyWidget(biography: superhero.biography),
                  ],
                ),
              ),
            ],
          );
        });
  }
}

class PowerStatsWidget extends StatelessWidget {
  final Powerstats powerstats;

  const PowerStatsWidget({Key? key, required this.powerstats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            "Powerstats".toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Center(
                child: PowerstatWidget(
                    name: "Intelligence",
                    value: powerstats.intelligencePercent),
              ),
            ),
            Expanded(
              child: Center(
                child: PowerstatWidget(
                    name: "Strength", value: powerstats.strengthPercent),
              ),
            ),
            Expanded(
              child: Center(
                child: PowerstatWidget(
                    name: "Speed", value: powerstats.speedPercent),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Center(
                child: PowerstatWidget(
                    name: "Durability", value: powerstats.durabilityPercent),
              ),
            ),
            Expanded(
              child: Center(
                child: PowerstatWidget(
                    name: "Power", value: powerstats.powerPercent),
              ),
            ),
            Expanded(
              child: Center(
                child: PowerstatWidget(
                    name: "Combat", value: powerstats.combatPercent),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        const SizedBox(
          height: 36,
        ),
      ],
    );
  }
}

class PowerstatWidget extends StatelessWidget {
  final String name;
  final double value;

  const PowerstatWidget({Key? key, required this.name, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ArcWidget(
          value: value,
          color: calculateColorByValue(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: Text(
            "${(value * 100).toInt()}",
            style: TextStyle(
              color: calculateColorByValue(),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Color calculateColorByValue() {
    if (value <= 0.5) {
      return Color.lerp(Colors.red, Colors.orangeAccent, value / 0.5)!;
    } else {
      return Color.lerp(
          Colors.orangeAccent, Colors.green, (value - 0.5) / 0.5)!;
    }
  }
}

class ArcWidget extends StatelessWidget {
  final double value;
  final Color color;

  const ArcWidget({Key? key, required this.value, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArcCustomPainter(value: value, color: color),
      size: const Size(66, 33),
    );
  }
}

class ArcCustomPainter extends CustomPainter {
  final double value;
  final Color color;

  ArcCustomPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final backgroundPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawArc(rect, pi, pi, false, backgroundPaint);
    canvas.drawArc(rect, pi, pi * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ArcCustomPainter) {
      return oldDelegate.value != value && oldDelegate.color != color;
    }
    return true;
  }
}

class BiographyWidget extends StatelessWidget {
  final Biography biography;

  const BiographyWidget({Key? key, required this.biography}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SuperheroesColors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          if (biography.alignmentInfo != null)
            Align(
              alignment: Alignment.topRight,
              child: _AlignmentWidget(alignmentInfo: biography.alignmentInfo!),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 16,
                ),
                Center(
                  child: Text(
                    "Bio".toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  "Full name".toUpperCase(),
                  style: const TextStyle(
                      color: SuperheroesColors.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  biography.fullName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  "Aliases".toUpperCase(),
                  style: const TextStyle(
                      color: SuperheroesColors.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  biography.aliases.join(", "),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  "Place of birth".toUpperCase(),
                  style: const TextStyle(
                      color: SuperheroesColors.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  biography.placeOfBirth,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignmentWidget extends StatelessWidget {
  final AlignmentInfo alignmentInfo;

  const _AlignmentWidget({Key? key, required this.alignmentInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: alignmentInfo.color,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(20),
          ),
        ),
        height: 24,
        width: 70,
        child: Text(
          alignmentInfo.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class SuperheroAppBar extends StatelessWidget {
  const SuperheroAppBar({
    Key? key,
    required this.superhero,
  }) : super(key: key);

  final Superhero superhero;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      pinned: true,
      floating: true,
      expandedHeight: 348,
      backgroundColor: SuperheroesColors.background,
      actions: const [FavouriteButton()],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          superhero.name,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        background: CachedNetworkImage(
          imageUrl: superhero.image.url,
          fit: BoxFit.cover,
          placeholder: (context, url) {
            return const ColoredBox(color: SuperheroesColors.indigo);
          },
          errorWidget: (context, url, error) {
            return Container(
                color: SuperheroesColors.indigo,
                child: Image.asset(
                  SuperheroesImages.unknownImage,
                  width: 85,
                  height: 264,
                ));
          },
        ),
      ),
    );
  }
}

class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SuperheroBloc bloc =
        Provider.of<SuperheroBloc>(context, listen: false);

    return StreamBuilder<bool>(
        stream: bloc.observeIsFavourite(),
        initialData: false,
        builder: (context, snapshot) {
          final favourite =
              !snapshot.hasData || snapshot.data == null || snapshot.data!;
          return GestureDetector(
            onTap: () =>
                favourite ? bloc.removeFromFavourite() : bloc.addToFavourite(),
            child: Container(
              height: 52,
              width: 52,
              alignment: Alignment.center,
              child: Image.asset(
                favourite
                    ? SuperheroIcons.starFilled
                    : SuperheroIcons.starEmpty,
                height: 32,
                width: 32,
              ),
            ),
          );
        });
  }
}

class ErrorWidget extends StatelessWidget {
  const ErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SuperheroBloc bloc =
        Provider.of<SuperheroBloc>(context, listen: false);
    return Column(
      children: [
        AppBar(
          backgroundColor: SuperheroesColors.background,
        ),
        const SizedBox(
          height: 60,
        ),
        InfoWithButton(
          title: "Error happened",
          subtitle: "Please, try again",
          buttonText: "Retry",
          assetImage: SuperheroesImages.supermanImage,
          imageHeight: 106,
          imageWidth: 126,
          imageTopPadding: 22,
          onTap: () {
            bloc.retry();
          },
        ),
      ],
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: SuperheroesColors.background,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(
            color: SuperheroesColors.blue,
            strokeWidth: 4,
          ),
        ),
      ],
    );
  }
}
